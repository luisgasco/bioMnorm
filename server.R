

server = function(input, output,session) {
    # Generar un nuevo reactive dataframe cuando se recarga la página 
    # hace que se quede en color verde lo que se ha anotado previamente
    # (si sólo se hiciera una lectura al inicio, al correr en uns ervidor
    # no se podría ver el avance real porque sólo se cargarían los datos
    # la primera vez que se ejecuta el código)
    datos_reactive <- reactiveValues(data = loadData(db))
    # Contador de códigos. Ayudará a contabilizar el número de códigos seleccionados
    contador_codigos = reactiveVal()
    contador_codigos(0)
  
  # Función paramostrar la DataTable
    output$mytable = DT::renderDataTable({
      # Select dataframe info.
      datos_sel<- datos_reactive$data %>% select(filename_id,span,mention_class, codes,validated)
      DT::datatable(datos_sel,rownames=FALSE,
                    options = list(
                        deferRender = TRUE,
                        scrollY = 400,
                        scroller = TRUE,
                        autoWidth = TRUE,
                        columnDefs = list(list(visible=FALSE, targets=c(3))),
                        order = list(list(4,'asc'),list(3,'asc'))),
                    selection ="single",
                    extensions = c('Responsive',"Scroller")) %>%
          DT::formatStyle( 'validated',
                           target = 'row',
                           backgroundColor = DT::styleEqual(c(0, 1,2), c('#f4f4f4', '#cbffe0','#fffddc')),
                           fontWeight = 'bold')
      },server = TRUE)
  
  # Render interfaz gráfica asociada a cada mención
    output$info_code <- renderUI({
        # Se guarda como variable el número de fila seleccionada en el datatable
        row_sel <<- input$mytable_rows_selected
        # If row is not selected, don't show anything.
        if(!is.null(row_sel)){
            # Filter dataframe
            dicc_filt <- filtra_dict(datos_reactive$data,diccionario, row_sel) 
            # Get input ids
            abbrev_id(gsub("[.#-]","_",paste0("abbrevx_",datos_reactive$data[row_sel,]$filename_id)))
            composite_id(gsub("[.#-]","_",paste0("compositex_",datos_reactive$data[row_sel,]$filename_id)))
            context_id(gsub("[.#-]","_",paste0("contextx_",datos_reactive$data[row_sel,]$filename_id)))
            # If selected row has NOT annotation_included empty or null, read data from dataframe
            if (datos_reactive$data$annotation_included[row_sel] != "" & !is.na(datos_reactive$data$annotation_included[row_sel])){
                # Unsplit data contained in annotation_included field
                lista_valores = unlist(strsplit(datos_reactive$data$annotation_included[row_sel], split = "#"))
                is_abb <- if(lista_valores[1]=="") FALSE else as.logical(lista_valores[1])
                is_composite <- if(lista_valores[2]=="") FALSE else as.logical(lista_valores[2])
                need_context <- if(lista_valores[3]=="") FALSE else as.logical(lista_valores[3])
                code <- unlist(strsplit(datos_reactive$data$annotation_included[row_sel], split = "#"))[4]
                sem_rel <- unlist(strsplit(datos_reactive$data$annotation_included[row_sel], split = "#"))[5]
                no_code <- as.logical(datos_reactive$data$no_code[row_sel])
                prev_annotated <- as.logical(datos_reactive$data$previously_annotated[row_sel])
                # Generate UI
                generate_reactive_ui(dicc_filt, datos_reactive$data, 
                                    is_abb, is_composite, need_context,
                                    code, sem_rel,no_code, prev_annotated)

            }
            else{
                # Create UI with empty fields
                generate_reactive_ui(dicc_filt, 
                                     datos_reactive$data,
                                     is_abb=FALSE,
                                     is_composite=FALSE,
                                     need_context=FALSE,
                                     code="",
                                     sem_rel="",
                                     no_code =as.logical(datos_reactive$data$no_code[row_sel]),
                                     previously_annotated = as.logical(datos_reactive$data$previously_annotated[row_sel]))
            }
            }else{
                tags$p("Select row")
           }
      })
  
    # Oserve if full_text is clicked to show the text output or not
    observeEvent(input[["full_text"]],{
        if(input[["full_text"]]==TRUE){
            shinyjs::show("texto_output")
        }else {
                shinyjs::hide("texto_output")
        }
        }
        )
  
    # Observe if context_id() is clicked to enable and disable the full_text button
    observeEvent(input[[context_id()]],{
        if (input[[context_id()]]==TRUE){
            shinyjs::enable("full_text")
        }else if(input[[context_id()]]==FALSE){
            shinyjs::disable("full_text")
        }
        }
        )

    # Create datatable proxy to update tables dinamically
    proxy1 <- DT::dataTableProxy('mytable')
    
    # Observe if previously_annotated is clicked to enable and idsable the candidate_list_elemen html field
    observeEvent(input$previously_annotated,{
        # Si el valor es TRUE
        if (input$previously_annotated){
            #Deshabilitamos el bloque de anotaciones
            shinyjs::disable(id="candidate_list_elem")
        }
        else{
                shinyjs::enable(id="candidate_list_elem")
        }
        })
    
    # Observe if save_data is clicked to save data into database
    observeEvent(input$save_data, {
        # Filter dataframe
        dicc_filt <- filtra_dict(datos_reactive$data,diccionario, row_sel) 

        
        # If previously_annotated is selected, we do not check the number of codes selected. 
        # we can save empty data to database.
        if(input$previously_annotated){
            # ACtualizamos datos reactivos y actualizamos/cambiamos datos de la tabla
            datos_reactive$data[row_sel,] = update_dataframe(datos=datos_reactive$data,
                                                             input=input,
                                                             code= "NO_NEED",
                                                             name_relbox_code=name_relbox_code)
            proxy1 %>% DT::replaceData(datos_reactive$data)
            # Subimos los datos a la base de datos
            db$update(query = query_uid(datos_reactive$data[row_sel,1]),
                      jsonlite::toJSON(list("$set" = list("annotation_included" = datos_reactive$data[row_sel,]$annotation_included,
                                                          "validated" = datos_reactive$data[row_sel,]$validated,
                                                          "previously_annotated" = as.logical(datos_reactive$data[row_sel,]$previously_annotated),
                                                          "no_code" = as.logical(datos_reactive$data[row_sel,]$no_code))), auto_unbox = TRUE, pretty = FALSE)
                      ) 
        }
        else{
            # We do two loops. The first one check that there is only one code 
            # selected. If there are more than one code, a pop-up message is shown
            # to the user.
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
            
            # The second for loop check some rules and save the data in the mongodb  
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
                                datos_reactive$data[row_sel,] = update_dataframe(datos=datos_reactive$data,
                                                                                 input=input,
                                                                                 code= dicc_filt$code[i],
                                                                                 name_relbox_code=name_relbox_code)
                                proxy1 %>% DT::replaceData(datos_reactive$data)
                                # Subimos los datos a la base de datos
                                db$update(query = query_uid(datos_reactive$data[row_sel,1]),
                                          jsonlite::toJSON(list("$set" = list("annotation_included" = datos_reactive$data[row_sel,]$annotation_included,
                                                                              "validated" = datos_reactive$data[row_sel,]$validated,
                                                                              "previously_annotated" = as.logical(datos_reactive$data[row_sel,]$previously_annotated),
                                                                              "no_code" = as.logical(datos_reactive$data[row_sel,]$no_code))), auto_unbox = TRUE, pretty = FALSE)
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
                            datos_reactive$data[row_sel,] = update_dataframe(datos=datos_reactive$data,
                                                                             input=input,
                                                                             code= "",
                                                                             name_relbox_code=name_relbox_code)
                            proxy1 %>% DT::replaceData(datos_reactive$data)
                            # Subimos los datos a la base de datos
                            db$update(query = query_uid(datos_reactive$data[row_sel,1]),
                                      jsonlite::toJSON(list("$set" = list("annotation_included" = datos_reactive$data[row_sel,]$annotation_included,
                                                                          "validated" = datos_reactive$data[row_sel,]$validated,
                                                                          "previously_annotated" = as.logical(datos_reactive$data[row_sel,]$previously_annotated),
                                                                          "no_code" = as.logical(datos_reactive$data[row_sel,]$no_code))), auto_unbox = TRUE, pretty = FALSE)
                            )
                        }
                        
                    }else{
                        # Do nothing
                        }
                    }
                }
    
            }
      },ignoreInit = TRUE)  

  
    # Render text around mention in the UI
    output$texto_output = renderUI({
        ## Compute needed filters
        row_sel <- input$mytable_rows_selected
        # Get filename related to the mention from dataframe. 
        file_name = unlist(strsplit(datos[row_sel,]$filename_id,split="#"))[1] #"es-S0210-56912007000900007-3"
        # Build the query
        query_get_text = paste0('{','"filename_id"',':"',file_name,'"}')
        # Get Text
        texto = db_text$find(query = query_get_text)$text
        # DATA WILL BE SAVE WITH A BUTTON
        # If row is not selected, don't show anything.
        if (!is.null(row_sel)){
            HTML(calcula_texto(TRUE,datos[row_sel,],texto, "clase_show"))
            }
        })

    
  # DEBUG Outputs
  # output$x4 = renderPrint({
  #   s = input$mytable_rows_selected
  #   if (length(s)) {
  #   cat(s)
  #   }
  # })
}