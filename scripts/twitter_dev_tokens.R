# TOKENS TWITTER #####
library(rtweet)
#

app_name <- "pol_ar_bot"

# Twittter developer account https://developer.twitter.com/
consumer_key <- "YourConsumerKeyCode"
consumer_secret <- "YourConsumerSecretCodeFromTwitter"
access_token <- "TheTwitterAppAccesoToken"
access_secret <- "TheTwitterAppAccesSecretCode"

#
#

token <- rtweet::create_token(set_renv = F,app_name, consumer_key, consumer_secret, access_token , access_secret )

token

#
### save token to home directory
#
path_to_token <- file.path(".twitter_token.rds")
saveRDS(token, path_to_token)

### create env variable TWITTER_PAT (with path to saved token)
env_var <- paste0("TWITTER_PAT=", path_to_token)
#
### save as .Renviron file (or append if the file already exists)
cat(env_var, file = file.path(".Renviron"), 
    fill = TRUE, append = TRUE)
#
### refresh .Renviron variables
readRenviron(".Renviron")

file.edit("~/.Renviron")

