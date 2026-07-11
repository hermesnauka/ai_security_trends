// VULNERABLE — do not use in production
prompt := fmt.Sprintf("Answer using this document.\nDocument: %s\nQuestion: %s", retrievedDoc, question)
answer, err := llmClient.Complete(ctx, prompt)
