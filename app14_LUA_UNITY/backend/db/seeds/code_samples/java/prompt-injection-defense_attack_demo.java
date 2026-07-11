// VULNERABLE — do not use in production
String prompt = "Answer using this document.\nDocument: " + retrievedDoc + "\nQuestion: " + question;
String answer = chatClient.call(prompt);
