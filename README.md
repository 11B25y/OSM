# OSM

## OpenAI API Key

The app uses the OpenAI API in `Views/OpenAIAPI.swift`. The API key is not stored in the source code. Provide your key at runtime using the `OPENAI_API_KEY` environment variable or by adding an `OPENAI_API_KEY` entry to the application's `Info.plist`.

The OpenAI model can also be configured via an `OPENAI_MODEL` environment variable or `OPENAI_MODEL` key in `Info.plist`. If no value is provided, the code defaults to the modern `gpt-3.5-turbo` model.
