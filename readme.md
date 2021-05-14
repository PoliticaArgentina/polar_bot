# Twitter bot electoral para {polAr} <a><img src="hex/polArbot.png" width="200" align="right" /></a>

* El diseño del _bot_ está basado en **[ggplotme](https://twitter.com/ggplotme)** de [@jcrodriguez1989](https://github.com/jcrodriguez1989/). 

* Utiliza funciones para la obtención de datos y visualización de la primera versión de **[{polAr}](https://electorarg.github.io/polAr/)** 

* Las consultas y publicación de contenido a través de la API de Twitter funcionan gracias a **[{rtweet}](https://docs.ropensci.org/rtweet/)**. 

---
## Descricpción del proyecto

* [Script](https://github.com/PoliticaArgentina/polar_bot/blob/master/scripts/twitter_dev_tokens.R) para generar archivo `.rds` con Token generado para acceso a la cuenta de Twitter 

* archivo [`bot.R`](https://github.com/PoliticaArgentina/polar_bot/blob/master/scripts/bot.R) que se comunica con API de _Twitter_ y busca menciones a la cuenta del bot,  consultando por resultados de una elección. El script realiza luego una serie de filtros para minimizar respuestas a menciones que no tienen relación con una elección. Cumplido esos pasos genera un data set `mentions2` que son los tuits que debe responder. 

* la función `post_the_tweet` , junto a `mentions2` son pasadas en una iteración para ir respondiendo las menciones filtradas una a una. Si se encuentra la elección se graficará el resultado y se guarda archivo en plots. Si no se encuentra en el repo, se responderá un mensaje de error con un archivo pre cargado en carpeta plots. 

* la carpeta plots es el lugar donde se guara el archivo temporal `plot.png` en el que el script grafica el resultado de la elección con la que responderá cada mención y otro llamado `fraude.png` que utiliza cuando no encuentra una elección (con mensaje de error). 

## Dependencias

Para correr el bot requiere de varios paquetes que tienen que estar instalados. En el script están llamados explicitamente antes de cada función de su NAMESPACE: 

Varias del _suite_ `tidyverse` (se puede instalar con `install.packages("tidyverse")`)

* `magrittr`

* `dplyr`

* `stringr`

* `purrr`

* `ggplot2`


Además tienen que estar instaladas `polAr` y `rtweet`. 

```
# install.packages('devtools') si no tiene instalado devtools

devtools::install_github("electorArg/polAr")

install.packages("rtweet")

```


## EJECUCIÓN

Con el siguiente comando (especificando el encoding, es importante) se puede correr el bot con un cron. Si no encuentra menciones que tengan que ser respondidas, imprimirá mensaje alusivo. Caso contrario responderá a la lista de menciones detectadas (ya sean con error o con resultado correcto)

```
source(file = "script/bot.R", encoding = "UTF8")

```
