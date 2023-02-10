# bioMnorm

This repository provides a shiny application to facilitate the manual entity normalization process for biomedical entities given a list of candidates generated using ranking methodologies. 

## Installation
You need to have a local mongodb database and docker-compose installed beforehand.

First clone this git repository. 

``` bash
git clone https://github.com/luisgasco/bioMnorm.git
```

Then, modify the '.config_file' file by selecting the port where your database is running, the name of the database, the collection where you have saved the annotations and the collection where you have saved the texts. In addition, you must also provide the path to the ontology dictionary you have used to predict candidate codes for each of your mentions. 

After that, you can run docker-compose to access the application in the web browser
``` bash
docker-compose -f docker-compose.yml up
```

## Database format

The 'MONGODB_COLLECTIONANNOTATION' is a collection with the following fields: 

- *filename_id*: String with the structure filename#initial_char_of_mention#end_char_of_mention
- *mention_class*: Type of mention (i.e. PROCEDIMIENTO)
- *span*: The mention extracted from texts
- *codes*: A list of candidate codes (It is a string with format: '[123,456,785,165]')
- *validated*: Must be 0 or empty when loading the collection.
- *annotation_included*: String with the result of the validation in the format is_abbreviature#is_composite#need_context#code#semantic_relation (i.e: TRUE#FALSE#FALSE#123#EXACT represent that the mention is an abbreviature, it is not composite, it doesn't need context to be normalized, it has the code 123 with the semantic relation exact)
- *no_code*: Logical variable that must be False when loading the collection. When the value is true means that there wasn't any correct code among the candidate list code.
- *previously_annotated*: A logical variable used to indicate that the code previously was been manually annotated.

The 'MONGODB_COLLECTIONTEXTS' is a collection with the following fields:
- *filename_id*: Name of the document. 
- *text*: Text of the document.

## Load dummy_data
We provide some dummy data to show you what is the correct format of each database. Please follow the following process to load into your MongoDB instance:

1. Go to the data folder
``` bash
cd data
```

2. Load annotation data:
``` bash
mongoimport  --db annot_norm_test --collection test_annotations --file=results_test2.tsv --type=tsv --headerline
```

3. Load text data:
``` bash
mongoimport  --db annot_norm_test --collection test_texts --file=texts_test2.tsv --type=tsv --headerline
```

Note: You can also upload json files following this structure:
``` bash
mongoimport  --db DB_NAME --collection COLLECTION_NAME --file=JSON_FILE_NAME.json --type=json --jsonArray
```


## License
MIT License

## You may also like…

  - [Noytext](https://github.com/luisgasco/Ropensky) - A web-based platform for annotating short-text documents to be used in applied     text-mining based research.
  - [ropenskyr](https://github.com/luisgasco/openskyr) - R library to get data from OpenSky Network API.
 

-------


> [luisgasco.es](http://luisgasco.es/) · GitHub:
> [@luisgasco](https://github.com/luisgasco) · Twitter:
> [@luisgasco](https://twitter.com/luisgasco) · Facebook: [Luis Gascó
> Sánchez
> page](https://www.facebook.com/Luis-Gasco-Sanchez-165003227504667)

  <a href="https://paypal.me/luisgasco?locale.x=es_ES">
    <img src="https://img.shields.io/badge/$-donate-ff69b4.svg?maxAge=2592000&amp;style=flat">
  </a>
