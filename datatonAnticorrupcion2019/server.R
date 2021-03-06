library(shiny)
library(dplyr)
library(magrittr)

library(pracma)

shinyServer(function(input, output, session) {

  output$imgJuan <- renderImage({
    if (session$clientData$output_imgJuan_width < 900) {
      width <- session$clientData$output_imgJuan_width
    } else {
      width <- 900
    }
    list(src = paste0("www/datosJuan/graficas_asociados/redes/red_",
                      input$selJuan,
                      ".0.png"),
         contentType = 'image/png',
         width = width
    )}, deleteFile = FALSE)
  

output$imgMitchell <- renderImage({
  if (session$clientData$output_imgMitchell_width < 900) {
    width <- session$clientData$output_imgMitchell_width
  } else {
    width <- 900
  }
  list(src = paste0("www/datosMitchell/datos mitch/red_",
                    input$selMitch,
                    ".png"),
       contentType = 'image/png',
       width = width
  )}, deleteFile = FALSE)

output$imgGina <- renderImage({
  if (session$clientData$output_imgGina_width < 900) {
    width <- session$clientData$output_imgGina_width
  } else {
    width <- 900
  }
  list(src = paste0("www/datosGina/red_gina_",
                    input$selGina,
                    ".png"),
       contentType = 'image/png',
       width = width
  )}, deleteFile = FALSE)

output$persistencia1 <- renderForceNetwork({
  contr <- read.csv("contratacionesShort.csv")
  contr %<>% dplyr::filter(., contr$roles != "b")
  contr %<>% transmute(., roles = as.character(roles),
                       id = as.character(id),
                       year  = as.integer(year),
                       size = as.integer(awds),
                       month, ocid)
  contr$size[is.na(contr$size)] <- 0
  contr$group <- ifelse(contr$roles == "p", 1, 2)
  contr2 <- contr
  contr <- select(contr, -ocid)
  
  inicio <- strsplit(input$inicio1, ":", fixed=FALSE)
  fin <- strsplit(input$fin1, ":", fixed=FALSE)
  
  contrFiltrada1 <- dplyr::filter(contr, (contr$year == as.integer(inicio[[1]][1]) & 
                                            contr$month >= as.integer(inicio[[1]][1])) |
                                    (contr$year == as.integer(fin[[1]][1]) & 
                                       contr$month <= as.integer(fin[[1]][2])) |
                                    (contr$year > as.integer(inicio[[1]][1]) & 
                                       contr$year < as.integer(fin[[1]][1]))) %>% 
    select(., id, size, group)
  
  contrFiltrada1 <- aggregate(. ~ id + group, contrFiltrada1, sum)
  
  contrFiltrada1['indiceNodes'] <- 1:nrow(contrFiltrada1) - 1
  
  
  ### links
  
  finalLink1 <- data.frame()
  
  
  contrPeriodo <- filter(contr2, (year == as.integer(inicio[[1]][1]) & 
                                    month >= as.integer(inicio[[1]][2])) |
                           (year==as.integer(fin[[1]][1]) &
                              month <= as.integer(fin[[1]][2])) |
                           (year>as.integer(inicio[[1]][1]) &
                              year<as.integer(fin[[1]][1]))) %>% 
    select(., id, size, group, ocid)
  
  
  for(i in unique(contrPeriodo$ocid)){
    
    contr_i <- dplyr::filter(contrPeriodo, contrPeriodo$ocid == i)
    orig <- dplyr::filter(contr_i, contr_i$group == 1)
    targets <- dplyr::filter(contr_i, contr_i$group != 1)
    
    for(licitante in 1:nrow(targets)){
      
      link_i <- data.frame(orig$id[1], targets$id[licitante],  
                           #targets$size[licitante])
                           1)
      names(link_i) <- c("source", "target", "value")
      finalLink1 <- rbind(finalLink1, link_i)
      
    }
    
  } # end forcontrPeriod
  
  
  ID1s <- transmute(contrFiltrada1, source = id, sourceID = indiceNodes)
  final1 <-  merge(finalLink1, ID1s, 
                   by.x = "source", by.y = "source", all.x = T, no.dups = F)
  ID1t <- transmute(contrFiltrada1, target = id, targetID = indiceNodes)
  final1 <-  merge(final1, ID1t, 
                   by.x = "target", by.y = "target", all.x = T, no.dups = F)
  
  contrFiltrada1$sizeReduced <- ifelse(contrFiltrada1$size == 0, 0, nthroot(contrFiltrada1$size,5))
  
  contrFiltrada1$distance <- 120*contrFiltrada1$sizeReduced
  contrFiltrada1$label <- paste0(substr(contrFiltrada1$id, 1, 3), ": $",
                                 as.character(contrFiltrada1$size))
  
  forceNetwork(Links = final1, Nodes = contrFiltrada1,
               Source = "sourceID", Target = "targetID",
               Value = "value", NodeID = "label", 
               Nodesize = "sizeReduced",
               Group = "group", opacityNoHover = 2,
               opacity = 1, zoom = T, bounded = T,
               fontSize = 15,linkDistance =120)
  
})

output$persistencia2 <- renderForceNetwork({
  
  inicio <- strsplit(input$inicio2, ":", fixed=FALSE)
  fin <- strsplit(input$fin2, ":", fixed=FALSE)
  contr <- read.csv("contratacionesShort.csv")
  contr %<>% dplyr::filter(., contr$roles != "b")
  contr %<>% transmute(., roles = as.character(roles),
                       id = as.character(id),
                       year  = as.integer(year),
                       size = as.integer(awds),
                       month, ocid)
  contr$size[is.na(contr$size)] <- 0
  contr$group <- ifelse(contr$roles == "p", 1, 2)
  contr2 <- contr
  contr <- select(contr, -ocid)
  
  contrFiltrada2 <- filter(contr, (year == as.integer(inicio[[1]][1]) & 
                                     month >= as.integer(inicio[[1]][1])) |
                             (year == as.integer(fin[[1]][1]) & 
                                month <= as.integer(fin[[1]][2])) |
                             (year > as.integer(inicio[[1]][1]) & 
                                year < as.integer(fin[[1]][1]))) %>% 
    select(., id, size, group)
  
  contrFiltrada2 <- aggregate(. ~ id + group, contrFiltrada2, sum)
  contrFiltrada2['indiceNodes'] <- 1:nrow(contrFiltrada2) - 1
  finalLink2 <- data.frame()
  contrPeriodo <- filter(contr2, (year == as.integer(inicio[[1]][1]) &
                                    month >= as.integer(inicio[[1]][2])) |
                           (year == as.integer(fin[[1]][1]) & 
                              month <= as.integer(fin[[1]][2])) |
                           (year > as.integer(inicio[[1]][1]) & 
                              year < as.integer(fin[[1]][1]))) %>% 
    select(., id, size, group, ocid)
  
  
  for(i in unique(contrPeriodo$ocid)){
    
    contr_i <- dplyr::filter(contrPeriodo, contrPeriodo$ocid == i)
    orig <- dplyr::filter(contr_i, contr_i$group == 1)
    targets <- dplyr::filter(contr_i, contr_i$group != 1)
    
    for(licitante in 1:nrow(targets)){
      
      link_i <- data.frame(orig$id[1], targets$id[licitante],  
                           #targets$size[licitante])
                           1)
      names(link_i) <- c("source", "target", "value")
      finalLink2 <- rbind(finalLink2, link_i)
      
    } # end for ocid
    
  } #end for cotrPeriod
  
  ID2s <- transmute(contrFiltrada2, source = id, sourceID = indiceNodes)
  final2 <-  merge(finalLink2, ID2s, 
                   by.x = "source", by.y = "source", all.x = T, no.dups = F)
  ID2t <- transmute(contrFiltrada2, target = id, targetID = indiceNodes)
  final2 <-  merge(final2, ID2t, 
                   by.x = "target", by.y = "target", all.x = T, no.dups = F)
  contrFiltrada2$sizeReduced <- ifelse(contrFiltrada2$size == 0, 0, nthroot(contrFiltrada2$size,5))
  
  contrFiltrada2$label <- paste0(substr(contrFiltrada2$id, 1, 3), ": $",
                                 as.character(contrFiltrada2$size))
  forceNetwork(Links = final2, Nodes = contrFiltrada2,
               Source = "sourceID", Target = "targetID",
               Value = "value", NodeID = "label", 
               Nodesize = "sizeReduced",
               Group = "group", opacityNoHover = 2,
               opacity = 1, zoom = T, bounded = T,
               fontSize = 15,linkDistance =120)
  
}) #end persistencia2

})
