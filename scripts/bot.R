#' Robot polAr> polar_bot
#' based on ggplotme https://github.com/jcrodriguez1989/ggplotme

library(magrittr) # pipe

# AVAILABLE ELECTIONS - polAr ####
# get available elections and create categories for tweets request matching
elecciones <- polAr::show_available_elections() %>% 
  dplyr::mutate(CATEGORIA = dplyr::case_when(category == "presi" ~ "PRESI",
                                             category == "dip" ~ "DIP",
                                             category == "sen" ~ "SEN"),
                TURNO = dplyr::case_when(round == "gral" ~ "GENERAL",
                                         round == "paso" ~ "PASO",
                                         round == "balota" ~ "BALOT"),
                NOMBRE2 = dplyr::case_when(NOMBRE == "CORDOBA" ~ "DOBA",
                                           NOMBRE == "TUCUMAN" ~ "TUCUM",
                                           NOMBRE == "NEUQUEN" ~ "NEUQU",
                                           NOMBRE == "RIO NEGRO" ~ "NEGRO",
                                           NOMBRE == "ENTRE RIOS" ~ "ENTRE", T~ NOMBRE
                ))


### SEARCH MENTIONS #####
# set user for twitter mentions search and timeline
user = "pol_Ar_bot"
mentions <- rtweet::search_tweets(user, n=300, include_rts = FALSE)  %>% rtweet::plain_tweets()
replies <-  rtweet::get_timeline(user, n = 300)
replies <- if(dim(replies)[1]>0){
  replies
}else{
  replies %>% dplyr::mutate(reply_to_status_id = 0)
}


# FILTER mentios that need reply

# Vector needed to drop non election tuits with mentions to user
categoria_check_election <- c("dip", "sen", "presi")
round_check <- c("paso", "gene")

mentions2 <- mentions %>%
  dplyr::filter(!screen_name == user) %>% 
  dplyr::filter(!status_id %in% replies$reply_to_status_id) %>% 
  #  dplyr::filter(display_text_width > 25) %>%  # minimum characters count with a (almost) correct election query and not other short msg
  dplyr::filter(!quoted_screen_name %in% user) %>%    # remove quotations to user
  dplyr::filter(stringr::str_detect(stringr::str_to_lower(text), 
                                    paste(categoria_check_election, 
                                          collapse = "|"))) %>% # remove "non electoral tuits"
  dplyr::filter(stringr::str_detect(stringr::str_to_lower(text),  # round requirement for answer filter
                                    paste(round_check, 
                                          collapse = "|")))
# REPLIES #####

#### CREATE reply with election function

post_the_tweet <- function(x, output) {
  
  # extract election request info from tweet 
  
  text <-  x[5] %>% as.character() %>% 
    stringr::str_to_lower() %>% 
    stringr::str_replace_all("ó", "o")%>% 
    stringr::str_replace_all("é", "e")%>% 
    stringr::str_replace_all("í", "i")%>% 
    stringr::str_replace_all("ú", "u")%>% 
    stringr::str_replace_all("á", "a")
  
  
  
  # parse request to match electoral data
  provincia_buscar <- try(stringr::str_match(text, stringr::str_to_lower(unique(elecciones$NOMBRE2))) %>% 
                            stats::na.exclude() %>% as.character())
  if(purrr::is_empty(provincia_buscar)){provincia_buscar <- "FALSE"}
  provincia <- elecciones %>% dplyr::filter(stringr::str_to_lower(NOMBRE2) == provincia_buscar) %>% 
    dplyr::select(district) %>% 
    dplyr::distinct() %>% as.character()
  
  
  category_buscar <- try(stringr::str_match(text, stringr::str_to_lower(unique(paste0(elecciones$CATEGORIA, "*")))) %>% 
                           stats::na.exclude() %>% as.character()) 
  if(purrr::is_empty(category_buscar)){category_buscar <- "FALSE"}
  
  category <- elecciones %>% dplyr::filter(stringr::str_to_lower(CATEGORIA) == category_buscar) %>% 
    dplyr::select(category) %>% 
    dplyr::distinct() %>% as.character()
  
  
  round_buscar <- try(stringr::str_match(text, stringr::str_to_lower(unique(paste0(elecciones$TURNO, "*")))) %>% 
                        stats::na.exclude() %>% as.character())
  if(purrr::is_empty(round_buscar)){round_buscar <- "FALSE"}
  
  round <- elecciones %>% dplyr::filter(stringr::str_to_lower(TURNO) == round_buscar) %>% 
    dplyr::select(round) %>% 
    dplyr::distinct() %>% as.character()
  
  
  year <- try(stringr::str_match(text, unique(elecciones$year))%>%  stats::na.exclude() %>% as.double())
  if(purrr::is_empty(year)){year <- "FALSE"}
  
  
  # select electoral data to answer tweets requests with try_error check
  
  
  
  download_data <- try(polAr::get_election_data(provincia, category, round, year) %>% polAr::get_names(), silent = TRUE)
  
  if(class(download_data)[1]=="try-error"){
    
    # do tweet
    suppressMessages(rtweet::post_tweet(
      status = glue::glue("SE AFANARON LA ELECCION...FRAUDE!!!
              No encontramos registro de esas elecciones. Fijate las disponibles en https://electorarg.github.io/PolAr_Data/"),
      media = "plots/fraude.png",
      in_reply_to_status_id = x[2],
      auto_populate_reply_metadata  = TRUE 
    ))
    
    
  }else{
    
    mensaje <- if(category != "presi"){
      # needed for tweets msg 
      download_data %>% 
        dplyr::arrange(dplyr::desc(votos)) %>% 
        dplyr::slice(1:2) %>% 
        dplyr::mutate(dif = votos - dplyr::lead(votos)) %>% 
        dplyr::filter(!is.na(dif))
      
    }else{
      download_data %>% 
        dplyr::group_by(nombre_lista) %>% 
        dplyr::summarise(votos = sum(votos)) %>% 
        dplyr::arrange(dplyr::desc(votos)) %>%
        dplyr::slice(1:2) %>% 
        dplyr::mutate(dif = votos - dplyr::lead(votos)) %>% 
        dplyr::filter(!is.na(dif))
    }
    
    
    
    # conditional plots (presidential must be national plot for consistency)
    plot <-  if(unique(download_data$category == "presi")){
      
      
      
      polAr::plot_results(download_data, national = TRUE) 
      
    }else{
      
      polAr::plot_results(download_data)
      
    }
    
    # save plot
    ggplot2::ggsave(plot = plot, "plots/plot.png")
    
    
    
    # do tweet
    suppressMessages(rtweet::post_tweet(
      status = glue::glue("{mensaje$nombre_lista} fue el + votado con una diferencia de {mensaje$dif} votos."),
      media = "plots/plot.png",
      in_reply_to_status_id = x[2],
      auto_populate_reply_metadata  = TRUE 
    ))
    
  }  
  
}

# check for unreplied tweets
if(dim(mentions2)[1]<1){
  
  print("NO HAY TWEETS PENDIENTES")
  
  
} else{ 
  # apply post_the_tweet for every request in mentions2 
  apply(mentions2, 1, post_the_tweet)}