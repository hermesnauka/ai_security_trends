// VULNERABLE — do not use in production
val prompt = s"Answer using this document.\nDocument: $retrievedDoc\nQuestion: $question"
llmClient.complete(prompt)
