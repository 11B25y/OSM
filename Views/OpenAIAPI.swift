import Foundation

let apiKey = "your-actual-api-key-here"

// Function to get response from OpenAI API
func getResponse(from prompt: String, completion: @escaping (String?) -> Void) {
    guard let url = URL(string: "https://api.openai.com/v1/completions") else {
        completion(nil)
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    
    // Prepare the body of the request with the prompt and model
    let body: [String: Any] = [
        "model": "text-davinci-003",  // You may want to update this to use a newer model, such as "gpt-3.5-turbo" or "gpt-4"
        "prompt": prompt,             // Pass the prompt dynamically
        "max_tokens": 150            // Adjust token size as needed
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
               let text = choices.first?["text"] as? String {
                completion(text)
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
