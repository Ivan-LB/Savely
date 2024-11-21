//
//  OpenAIClient.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 20/11/24.
//

import Foundation

class OpenAIClient {
    static let shared = OpenAIClient()

    private let apiKey: String

    private init?() {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let apiKey = dict["OPENAI_API_KEY"] as? String else {
            print("Error: API Key not found in Config.plist.")
            return nil
        }
        self.apiKey = apiKey
    }

    func fetchTip(prompt: String) async -> String? {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        // Construir el mensaje para el modelo
        let messages = [
            OpenAIChatMessage(role: "system", content: "Eres un asistente financiero."),
            OpenAIChatMessage(role: "user", content: prompt)
        ]
        
        let requestBody = OpenAIChatRequest(model: "gpt-4o-mini", messages: messages)
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Verificar el código de estado de la respuesta
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("Error: HTTP \(httpResponse.statusCode)")
                return nil
            }
            
            // Imprimir la respuesta JSON
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Response JSON: \(jsonString)")
            }

            // Decodificar la respuesta
            let decoder = JSONDecoder()
            // No establecer keyDecodingStrategy si usas CodingKeys
            let apiResponse = try decoder.decode(OpenAIChatResponse.self, from: data)
            if let content = apiResponse.choices.first?.message.content {
                return content.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            print("Error fetching tip from API: \(error)")
        }
        
        return nil
    }
}
