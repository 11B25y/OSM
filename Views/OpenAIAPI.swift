import Foundation

// Load the API key from a secure source. The key can be provided through the
// `OPENAI_API_KEY` environment variable or the application's Info.plist. This
// avoids storing the key directly in source code.
let apiKey: String = {
    if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
        return envKey
    }

    if let plistKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String {
        return plistKey
    }

    print("Warning: OPENAI_API_KEY not set")
    return ""
}()

// Load the OpenAI model to use. Defaults to gpt-3.5-turbo if not specified.
let openAIModel: String = {
    if let envModel = ProcessInfo.processInfo.environment["OPENAI_MODEL"] {
        return envModel
    }

    if let plistModel = Bundle.main.object(forInfoDictionaryKey: "OPENAI_MODEL") as? String {
        return plistModel
    }

    return "gpt-3.5-turbo"
}()

// Function to get response from OpenAI API
func getResponse(from prompt: String, completion: @escaping (String?) -> Void) {
    guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
        completion(nil)
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

    // Prepare the body of the request with the prompt and model
    let body: [String: Any] = [
        "model": openAIModel,
        "messages": [
            ["role": "user", "content": prompt]
        ]
    ]
    
    // Serialize the body to JSON format
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
    } catch {
        print("Error serializing JSON: \(error)")
        completion(nil)
        return
    }
    
    // Perform the network request
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error with request: \(error.localizedDescription)")
            completion(nil)
            return
        }
        
        guard let data = data else {
            print("No data received.")
            completion(nil)
            return
        }
        
        do {
            if let decodedResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let choices = decodedResponse["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                completion(content)
            } else {
                print("Unexpected response format")
                completion(nil)
            }
        } catch {
            print("Error decoding response: \(error.localizedDescription)")
            completion(nil)
        }
    }
    task.resume() // Start the data task
}
