tags$style("@import url(https://use.fontawesome.com/releases/v5.7.2/css/all.css);")

header <- dashboardHeader(title = "Basic dashboard")

  
sidebar <-dashboardSidebar(
  sidebarMenu(
    menuItem("anotaciones", tabName = "anotaciones")  )
)

## Body content
body <- dashboardBody(shinyjs::useShinyjs(),
                        tags$head(
                          tags$script(inactivity),
                          tags$link(rel = "stylesheet", type = "text/css", href = "mystyle.css")
                        ),
                        tabItems(
                          # First tab content
                          tabItem(tabName = "anotaciones",
                                  fluidRow(
                                  column(8,
                                      box(width = 12,
                                          status = "warning",
                                          height = 500,
                                          DT::dataTableOutput('mytable',height = "500px"))
                                      ,
                                         box(width = 12,
                                             title="Text",
                                             height = 250,
                                             htmlOutput("texto_output",style = "height:190px;overflow-y: scroll;"))
                                  ),
                                    column(4,
                                           box(width = 12,
                                               height = 750,
                                               uiOutput("info_code"))
                                    )
                                  )
                                  
                                  
                          )
                        )
                      )

dashboardPage(header, sidebar, body)


