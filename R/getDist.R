# Auxiliary function to get distribution and species number

getDist <- function(df,
                    listspp = NULL,
                    verbose = verbose) {

  # Creating empty lists to save data of interest during all search.
  if (listspp) {
    list_spp <- vector("list", length = length(df$powo_uri))
  }
  list_dist_nat <- vector("list", length = length(df$powo_uri))
  list_dist_nat_bot <- vector("list", length = length(df$powo_uri))
  list_dist_intr <- vector("list", length = length(df$powo_uri))
  list_dist_intr_bot <- vector("list", length = length(df$powo_uri))
  list_html <- vector("list", length = length(df$powo_uri))
  list_grepl <- vector("list", length = length(df$powo_uri))
  list_publ <- vector("list", length = length(df$powo_uri))

  for (i in seq_along(df$powo_uri)) {
    # The tryCatch function helps skipping error in for-loop.
    tryCatch({
      # Adding a pause 300 seconds of um pause every 500th search,
      # because POWO website cannot permit constant search.
      if (i%%500 == 0) {
        Sys.sleep(300)
      }

      if (!is.na(df$powo_uri[i])) {
        list_html[[i]] <- readLines(paste(df$powo_uri[i]), warn = F)
        # Adding a counter to identify each running search.
        if (listspp) {
          if (verbose) {
            print(paste0("Searching distribution and spp number of... ",
                         df$genus[df$powo_uri == df$powo_uri[i]], " ",
                         df$family[df$powo_uri == df$powo_uri[i]], " ", i, "/",
                         length(list_spp)))
          }
        } else {
          if (verbose) {
            ng <- df$genus[df$powo_uri == df$powo_uri[i]]
            ng <- ng[!is.na(ng)]
            ns <- df$species[df$powo_uri == df$powo_uri[i]]
            ns <- ns[!is.na(ns)]
            nf <- df$family[df$powo_uri == df$powo_uri[i]]
            nf <- nf[!is.na(nf)]
            print(paste0("Searching distribution of... ",
                         ng, " ",
                         ns, " ",
                         nf, " ", i, "/",
                         length(df$species[!is.na(df$species)])))
          }
        }

        if (listspp) {
          list_grepl[[i]] <- grepl(">Includes\\s", list_html[[i]])
          list_spp[[i]] <- gsub(".*>Includes\\s", "",
                                list_html[[i]][list_grepl[[i]]])
          list_spp[[i]] <- gsub("\\sAccepted.+", "",
                                list_spp[[i]][grepl("\\sAccepted\\s",
                                                    list_spp[[i]])])
        }

        list_dist_nat[[i]] <-
          gsub(".*Native\\sto[:]<[/]h3>\\s+<p\\sclass[=]\"p\">\\s+", "",
                                   paste0(list_html[[i]], collapse = ""))
        list_dist_nat[[i]] <- gsub("\\s+<.+", "", list_dist_nat[[i]])
        list_dist_nat[[i]] <- gsub("\\s{2,}", " ", list_dist_nat[[i]])

        list_dist_intr[[i]] <-
          gsub(".*Introduced\\sinto[:]<[/]h3>\\s+<p\\sclass[=]\"p\">\\s+", "",
               paste0(list_html[[i]], collapse = ""))
        list_dist_intr[[i]] <- gsub("\\s+<.+", "", list_dist_intr[[i]])
        list_dist_intr[[i]] <- gsub("\\s{2,}", " ", list_dist_intr[[i]])
        list_publ[[i]] <- gsub(".*First\\spublished\\sin\\s+", "",
                               paste0(list_html[[i]], collapse = ""))
        list_publ[[i]] <- gsub("\\s+<[/]div>.+", "", list_publ[[i]])

        list_dist_nat_bot[[i]] <- list_dist_nat[[i]]
        tf <- grepl("<", list_dist_nat_bot[[i]])
        if (any(tf)) {
          list_dist_nat_bot[[i]][tf] <- "unknown"
        }
        list_dist_intr_bot[[i]] <- list_dist_intr[[i]]
        tf <- grepl("<", list_dist_intr_bot[[i]])
        if (any(tf)) {
          list_dist_intr_bot[[i]][tf] <- "unknown"
        }

        # Correcting list of countries that come with different regions.
        list_dist_nat[[i]] <- botdiv_to_countries(list_dist_nat, i)
        list_dist_intr[[i]] <- botdiv_to_countries(list_dist_intr, i)
      }
      # The function below will print any search error (e.g. site address of a
      # specific genus is not opening for some reason).
    }, error = function(e) {cat(paste("ERROR:",
                                      df$genus[df$powo_uri == df$powo_uri[i]],
                                      df$family[df$powo_uri == df$powo_uri[i]]),
                                conditionMessage(e), "\n")})
  }

  # Filling in with "NA" those genera for which the search failed to open the
  # POWO site.
  if (listspp) {
    temp <- lapply(list_spp, is.null)
    list_spp[unlist(temp)] <- NA
    temp <- lapply(list_spp, function(x) length(x) == 0)
    list_spp[unlist(temp)] <- NA
    # Extracting the number of species from the list during the POWO searching.
    df$species_number <- unlist(list_spp, use.names = F)
    df$species_number <- as.numeric(df$species_number)
  }

  temp <- lapply(list_dist_nat, is.null)
  list_dist_nat[unlist(temp)] <- NA
  temp <- lapply(list_dist_nat, function(x) length(x) == 0)
  list_dist_nat[unlist(temp)] <- NA

  temp <- lapply(list_dist_nat_bot, is.null)
  list_dist_nat_bot[unlist(temp)] <- NA
  temp <- lapply(list_dist_nat_bot, function(x) length(x) == 0)
  list_dist_nat_bot[unlist(temp)] <- NA

  temp <- lapply(list_publ, is.null)
  list_publ[unlist(temp)] <- NA
  temp <- lapply(list_publ, function(x) length(x) == 0)
  list_publ[unlist(temp)] <- NA

  temp <- lapply(list_dist_intr, is.null)
  list_dist_intr[unlist(temp)] <- NA
  temp <- lapply(list_dist_intr, function(x) length(x) == 0)
  list_dist_intr[unlist(temp)] <- NA

  temp <- lapply(list_dist_intr_bot, is.null)
  list_dist_intr_bot[unlist(temp)] <- NA
  temp <- lapply(list_dist_intr_bot, function(x) length(x) == 0)
  list_dist_intr_bot[unlist(temp)] <- NA

  # Extracting the publication where the name was first published.
  df$publication <- NA
  df$publication <- unlist(list_publ, use.names = F)

  # Extracting the native distribution of each species from the list during the
  # POWO searching.
  df$native_to_country <- NA
  df$native_to_botanical_countries <- NA
  df$native_to_country <- unlist(list_dist_nat, use.names = F)
  df$native_to_botanical_countries <- unlist(list_dist_nat_bot, use.names = F)

  # Extracting the introduced distribution of each species from the list during
  # the POWO searching.
  df$introduced_to_country <- NA
  df$introduced_to_botanical_countries <- NA
  df$introduced_to_country <- unlist(list_dist_intr, use.names = F)
  df$introduced_to_botanical_countries <- unlist(list_dist_intr_bot,
                                                 use.names = F)

  # Removing any non-ASCII chars from the distribution list.
  df$native_to_country <- iconv(df$native_to_country,
                                from = "UTF-8", to = "ASCII//TRANSLIT")

  df$native_to_botanical_countries <- iconv(df$native_to_botanical_countries,
                                            from = "UTF-8",
                                            to = "ASCII//TRANSLIT")

  df$introduced_to_country <- iconv(df$introduced_to_country,
                                    from = "UTF-8", to = "ASCII//TRANSLIT")
  df$introduced_to_botanical_countries <-
    iconv(df$introduced_to_botanical_countries, from = "UTF-8",
          to = "ASCII//TRANSLIT")

  return(df)
}

# Secondary function to find related country for each botanical subdivision.
botdiv_to_countries <- function(x, i) {

  # Read data of botanical subdivisions and convert non-ASCII chars
  # botregions <- read.csv("dataraw/botanical_country_subdivisions.csv")
  # botregions$country <- iconv(botregions$country,
  #                             from = "UTF-8",
  #                             to = "ASCII//TRANSLIT")
  # botregions$botanical_division <- iconv(botregions$botanical_division,
  #                                        from = "UTF-8",
  #                                        to = "ASCII//TRANSLIT")
  # write.csv(botregions, "dataraw/botanical_country_subdivisions.csv",
  #           row.names=FALSE)

  # Read data of botanical subdivisions.
  utils::data("botregions", package = "expowo")

  # Find duplicated botanical regions
  # botregions$botanical_division[duplicated(botregions$botanical_division)]

  temp <- strsplit(x[[i]], ", ")[[1]]

  for (n in seq_along(temp)) {
    tf <- botregions$botanical_division %in% temp[n]
    if (length(botregions$country[tf]) == 0) {

      # use strtrim to limit the length of each character/botanical region
      # because POWO has limited chars.
      bot_temp <- strtrim(botregions$botanical_division, 20)
      tf <- bot_temp %in% temp[n]
      if (length(botregions$country[tf]) > 0) {

        temp[n] <- botregions$country[tf]
      }
    } else {
      if (any(!botregions$country[tf] %in% temp[n])) {

        if (length(botregions$country[tf]) > 1) {
          temp[n] <- paste(botregions$country[tf], collapse = ", ")
        } else {
          temp[n] <- botregions$country[tf]
        }
      }
    }
  }
  temp <- sort(unique(temp))

  x[[i]] <- paste(temp, collapse = ", ")

  g <- grepl("<", x[[i]])
  if (any(g)) {
    x[[i]][g] <- "unknown"
  }

  return(x[[i]])
}

