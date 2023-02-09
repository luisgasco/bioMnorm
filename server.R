

server = function(input, output,session) {
    
    
    # Generar un nuevo reactive dataframe cuando se recarga la página 
    # hace que se quede en color verde lo que se ha anotado previamente
    # (si sólo se hiciera una lectura al inicio, al correr en uns ervidor
    # no se podría ver el avance real porque sólo se cargarían los datos
    # la primera vez que se ejecuta el código)
    datos_reactive <- reactiveValues(data = loadData(db))
    contador_codigos = reactiveVal()
    contador_codigos(0)
  
  # Muestra el data table
  output$mytable = DT::renderDataTable({
    df <- datos_reactive$data %>% select(filename_id,span,mention_class, codes,validated,text)
    DT::datatable(df,rownames=FALSE,
                  filter = "top",
                  options = list(
                                 deferRender = TRUE,
                                 scrollY = 400,
                                 scroller = TRUE,
                                 autoWidth = TRUE, 
                                 columnDefs = list(list(visible=FALSE, targets=c(3,5)))),
                  selection ="single",
                  extensions = c('Responsive',"Scroller")) %>%
    DT::formatStyle( 'validated',
            target = 'row',
            backgroundColor = DT::styleEqual(c(0, 1), c('#FF5C5C', '#ECFFDC')),
            fontWeight = 'bold',
        )
  },server = TRUE)
  
  # Haz el renderUI de la mención selecciónada
  output$info_code <- renderUI({
          ## Compute needed filters
          row_sel <<- input$mytable_rows_selected
          

          # If row is not selected, don't show anything.
          if(!is.null(row_sel)){
            # Filtramos diccionario
            dicc_filt <- filtra_dict(datos_reactive$data,diccionario, row_sel) 
            # Ids de inputs:
            abbrev_id(gsub("[.#-]","_",paste0("abbrevx_",datos_reactive$data[row_sel,]$filename_id)))
            composite_id(gsub("[.#-]","_",paste0("compositex_",datos_reactive$data[row_sel,]$filename_id)))
            context_id(gsub("[.#-]","_",paste0("contextx_",datos_reactive$data[row_sel,]$filename_id)))
            # print(input[[context_id]])
            # Si seleciona una fila en el que el campo annotation_included esté vacio o sea nulo
            if (datos_reactive$data$annotation_included[row_sel] != "" & !is.na(datos_reactive$data$annotation_included[row_sel])){
                # Desacemos la string de valores almacenada en el DATAFRAME
                is_abb <- as.logical(unlist(strsplit(datos_reactive$data$annotation_included[row_sel], split = "#"))[1])
                is_composite <- as.logical(unlist(strsplit(datos_reactive$data$annotation_included[row_sel], split = "#"))[2])
                need_context <- as.logical(unlist(strsplit(datos_reactive$data$annotation_included[row_sel], split = "#"))[3])
                code <- unlist(strsplit(datos_reactive$data$annotation_included[row_sel], split = "#"))[4]
                sem_rel <- unlist(strsplit(datos_reactive$data$annotation_included[row_sel], split = "#"))[5]
                no_code <- as.logical(datos_reactive$data$no_code[row_sel])
                # Generamos UI
                generate_reactive_ui(dicc_filt, datos_reactive$data, 
                                    is_abb, is_composite, need_context,
                                    code, sem_rel,no_code)

            }else{
                generate_reactive_ui(dicc_filt, datos_reactive$data, 
                                     is_abb=FALSE, is_composite=FALSE, 
                                     need_context=FALSE,code="", sem_rel="",
                                     no_code =as.logical(datos_reactive$data$no_code[row_sel]))
            }
           }else{
                tags$p("Select row")
           }
          
      })
  
  observeEvent(input[["full_text"]],{
      # return_value <- shinyCatch(fn_warning())
      if(input[["full_text"]]==TRUE){
          shinyjs::show("texto_output")
          print("MOSTRAR")
      }else {
          shinyjs::hide("texto_output")
      }
  })
  
 
  observeEvent(input[[context_id()]],{
      if (input[[context_id()]]==TRUE){
          shinyjs::enable("full_text")
      }else if(input[[context_id()]]==FALSE){
          shinyjs::disable("full_text")
      }
      
  }
  )

 
  # Creamos proxy para actualizar tablas
  proxy1 <- DT::dataTableProxy('mytable')
  
  observeEvent(input$save_data, {
    print(input[[context_id()]])
    # Save to mongoDB
    print(input$save_data)
    dicc_filt <- filtra_dict(datos_reactive$data,diccionario, row_sel) 
    print("filename_id")
    print(datos_reactive$data$filename_id[row_sel])
    
    print("Checkboxes marcados")
    print("is_abb")
    print(input[[abbrev_id()]])
    print("is_composite")
    print(input[[composite_id()]])
    print("need_context")
    print(input[[context_id()]])
    print("NO_CODE")
    print(input[["no_code"]])
    print("GUARDAMOS CODIGO")
    
    ## ITERAMOS SOBRE 2 FOR LOOPs. 
    # Primero iteramos sobre todos los candidatos para verificar que sólo hay un 
    # código seleccionado. Si el contador es mayor que 
    # 1 sacamos un pop-up para indicar que se des-seleccionen.
    contador_codigos(0)
    for (j in 1:nrow(dicc_filt)) {
        # Generamos identificador para el checkbox y el radiobutton de sem_rel
        name_checkbox_code <- gsub("[.#-]","_",paste0("check_",dicc_filt$code[j],"_", datos_reactive$data$filename_id[row_sel]))
        name_relbox_code <- gsub("[.#-]","_",paste0("rel_",dicc_filt$code[j],"_", datos_reactive$data$filename_id[row_sel]))
        if (input[[name_checkbox_code]] ==TRUE){
            contador_codigos(contador_codigos() + 1 )
        }
        if(contador_codigos()>1){
            showModal(modalDialog(
                title =       "Selección incorrecta",
                easyClose = TRUE,
                HTML("Has seleccionado dos códigos de la lista de forma simultánea. \n Por favor, antes de guardar revisa los códigos seleccionados.
                      ")
            ))
            # Si hay dos códigos seleccionamos, evitamos que se entre al siguiente bucle
            enter2secondfor = FALSE
            break
        }else{
            # Si no hay dos códigos seleccionamos, indicamos al código que netre al segundo bucle.
            enter2secondfor = TRUE
        }
    }
    
    # Entramos en el segundo bucle, de guardado. 
    contador_codigos(0)
    if(enter2secondfor==TRUE){
        for (i in 1:nrow(dicc_filt)) {
            # Generamos identificador para el checkbox y el radiobutton de sem_rel
            name_checkbox_code <- gsub("[.#-]","_",paste0("check_",dicc_filt$code[i],"_", datos_reactive$data$filename_id[row_sel]))
            name_relbox_code <- gsub("[.#-]","_",paste0("rel_",dicc_filt$code[i],"_", datos_reactive$data$filename_id[row_sel]))
            # Contamos numero de códigos seleccionados
            if (input[[name_checkbox_code]] ==TRUE){
                contador_codigos(contador_codigos() + 1 )
            }
            
            # Logica selectores
            # Si algún codigo está seleccionado
            if (input[[name_checkbox_code]] ==TRUE){
                # Si el selector de relación semántica está seleccionado
                if (!is.null(input[[name_relbox_code]])){
                    # si el código de no_code está NO seleccionado
                    if(input[["no_code"]]==FALSE){
                        # ACtualizamos datos reactivos y actualizamos/cambiamos datos de la tabla
                        datos_reactive$data[row_sel,] = update_dataframe(datos=datos_reactive$data,input=input,code= dicc_filt$code[i],name_relbox_code=name_relbox_code)
                        proxy1 %>% DT::replaceData(datos_reactive$data)
                        # Subimos los datos a la base de datos
                        db$update(query = query_uid(datos_reactive$data[row_sel,1]),
                                  jsonlite::toJSON(list("$set" = list("annotation_included" = datos_reactive$data[row_sel,]$annotation_included,
                                                                      "validated" = datos_reactive$data[row_sel,]$validated)), auto_unbox = TRUE, pretty = FALSE)
                        )
                    }else{
                        #Popup para deseleccionar no_code si hay codigos seleccionados
                        showModal(modalDialog(title = "Selección incorrecta",
                                              "Has seleccionado que ningún código sugerido
                                          se puede asociar a la mención, pero has dejado marcado
                                          los códigos. Por favor deselecciona todos los
                                          códigos."
                        ))
                    }
                }else{
                    #POPUP para seleccionar semantic_relation
                    showModal(modalDialog(title = "Selección incorrecta",
                                          "No has seleccionado relación semántica asociada
                                      al código elegido."
                    ))
                    break
                }
                # Si no hay codigos seleccionados
            }else if((input[[name_checkbox_code]] ==FALSE)){
                # Pero el selector de no_code si que lo está
                if(input[["no_code"]]==TRUE){
                    # ACtualizamos datos reactivos y actualizamos/cambiamos datos de la tabla
                    datos_reactive$data[row_sel,] = update_dataframe(datos=datos_reactive$data,input=input,code= dicc_filt$code[i],name_relbox_code=name_relbox_code)
                    proxy1 %>% DT::replaceData(datos_reactive$data)
                    # Subimos los datos a la base de datos
                    db$update(query = query_uid(datos_reactive$data[row_sel,1]),
                              jsonlite::toJSON(list("$set" = list("annotation_included" = datos_reactive$data[row_sel,]$annotation_included,
                                                                  "validated" = datos_reactive$data[row_sel,]$validated)), auto_unbox = TRUE, pretty = FALSE)
                    )
                }
                
            }else{
                # NO GUARDAMOS NADA.
            }
        }
    }
    
    
  },ignoreInit = TRUE)  
 
  # observe(
  #     # Si se han seleccibserve(
  #     # Si se han seleccionado más de dos códigos y se ha tocado guardar:
  #     if (contador_codigos()>1){
  #         showModal(modalDialog(
  #             title =       "Selección incorrecta",
  #             HTML("Has seleccionado dos códigos de la lista de forma simultánea. \n Por favor, revisa la mención que acabas de guardar ya que puede 
  #             tener inconsistencias o resultados no esperados.
  #             ")
  #         ))
  #     }
  #     
  # )
  # Haz el render UI del texto
  output$texto_output = renderUI({
    ## Compute needed filters
    # TODO
    
    ## Compute needed filters
    row_sel <- input$mytable_rows_selected
    # GET DATA FROM TABLE TO DO QUERY IN MONGO EACH TIME. 
    # DATA WILL BE SAVE WITH A BUTTON
    # If row is not selected, don't show anything.
    if (!is.null(row_sel)){
      HTML(calcula_texto(TRUE,datos[row_sel,], "clase_show"))
    }
  })

    

  output$x4 = renderPrint({
    s = input$mytable_rows_selected
    if (length(s)) {
    cat(s)
    }
  })
  #output$TBL <- renderTable({
  #  NewDat()
  #})
}