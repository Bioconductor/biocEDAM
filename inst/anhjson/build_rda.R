# each is a one-element list with name for data.frame
library(jsonlite)
edam_data  = fromJSON("edam_data.json")
save(edam_data, file="edam_data.rda")
edam_formats = fromJSON("edam_formats.json")
save(edam_formats, file="edam_formats.rda")
edam_operations = fromJSON("edam_operations.json")
save(edam_operations, file="edam_operations.rda")
edam_topics = fromJSON("edam_topics.json")
save(edam_topics, file="edam_topics.rda")

