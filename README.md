# SwiftImageAnalyzer

A Swift package for analyzing images using various AI services, with built-in support for Google's Gemini Vision API.

## Features

- **Protocol-based Design**: Extensible `ImageAnalyzer` protocol for easy integration of different AI services
- **Gemini Vision API**: Built-in implementation using Google's Gemini Vision API
- **Multiple Input Types**: Support for image data, file URLs, and remote URLs
- **Configurable Prompts**: Customizable analysis prompts and parameters
- **Async/Await**: Modern Swift concurrency support
- **Comprehensive Error Handling**: Detailed error types with localized descriptions
- **Cross-platform**: Supports iOS 15+, macOS 12+, tvOS 15+, and watchOS 8+

## Installation

### Swift Package Manager

Add SwiftImageAnalyzer to your project by adding it as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/morganID/SwiftImageAnalyzer.git", from: "1.0.0")
]
```

Or add it to your Xcode project:
1. Go to File > Add Packages...
2. Enter `https://github.com/morganID/SwiftImageAnalyzer.git`
3. Select the version you want to use

## Quick Start

### Basic Image Analysis

```swift
import SwiftImageAnalyzer

// Initialize the analyzer with your Gemini API key
let analyzer = GeminiImageAnalyzer(apiKey: "your-api-key-here")

// Analyze an image from a file
let imageURL = URL(fileURLWithPath: "/path/to/your/image.jpg")
let result = try await analyzer.analyze(fileURL: imageURL)

print("Analysis: \(result.rawResponse)")
print("Processing time: \(result.metadata.processingTime ?? 0) seconds")
```

### Custom Configuration

```swift
// Create a custom configuration
let config = ImageAnalysisConfiguration(
    prompt: "Describe the mood and atmosphere of this image",
    temperature: 0.8,
    maxTokens: 500
)

// Analyze with custom configuration
let result = try await analyzer.analyze(
    fileURL: imageURL,
    configuration: config
)
```

### Different Input Types

```swift
// From Data
let imageData = try Data(contentsOf: imageURL)
let result = try await analyzer.analyze(
    data: imageData,
    mimeType: "image/jpeg"
)

// From remote URL
let remoteURL = URL(string: "https://example.com/image.png")!
let result = try await analyzer.analyze(remoteURL: remoteURL)
```

## YouTube Thumbnail Analysis

If you're migrating from a YouTube thumbnail analysis service, you can use the convenience methods:

```swift
// Create analyzer optimized for YouTube thumbnails
let analyzer = GeminiImageAnalyzer.youtubeThumbnailAnalyzer(apiKey: "your-api-key")

// Get the standard YouTube thumbnail configuration
let config = GeminiImageAnalyzer.youtubeThumbnailConfiguration()

// Analyze a thumbnail
let result = try await analyzer.analyze(
    remoteURL: thumbnailURL,
    configuration: config
)

// Parse the structured response with enhanced fields
if let parsedData = result.parsedData {
    let style = parsedData["style"] as? String
    let colors = parsedData["colors"] as? String
    let subject = parsedData["subject"] as? String
    let lighting = parsedData["lighting"] as? String
    let layout = parsedData["layout"] as? String
    let cameraAngle = parsedData["camera_angle"] as? String
    let shotType = parsedData["shot_type"] as? String
    let subjectPose = parsedData["subject_pose"] as? String
    let expression = parsedData["expression"] as? String
    let depthOfField = parsedData["depth_of_field"] as? String
    let lightingDirection = parsedData["lighting_direction"] as? String
    let colorTemperature = parsedData["color_temperature"] as? String
    let composition = parsedData["composition"] as? String
    let focus = parsedData["focus"] as? String
    let finalPrompt = parsedData["final_prompt"] as? String

    print("Style: \(style ?? "")")
    print("Camera Angle: \(cameraAngle ?? "")")
    print("Shot Type: \(shotType ?? "")")
    print("Subject Pose: \(subjectPose ?? "")")
    print("Expression: \(expression ?? "")")
    print("Depth of Field: \(depthOfField ?? "")")
    print("Final Prompt: \(finalPrompt ?? "")")
}
```

## Comprehensive Image Analysis

For detailed analysis of any image with all visual aspects:

```swift
// Create comprehensive analyzer
let analyzer = GeminiImageAnalyzer.comprehensiveImageAnalyzer(apiKey: "your-api-key")

// Use comprehensive configuration
let config = GeminiImageAnalyzer.comprehensiveImageConfiguration()

// Analyze any image
let result = try await analyzer.analyze(
    fileURL: imageURL,
    configuration: config
)

// Access all detailed fields
if let parsedData = result.parsedData {
    let mood = parsedData["mood"] as? String
    let textureDetails = parsedData["texture_details"] as? String
    let cameraAngle = parsedData["camera_angle"] as? String
    let subjectPose = parsedData["subject_pose"] as? String
    let expression = parsedData["expression"] as? String
    let depthOfField = parsedData["depth_of_field"] as? String
    let lightingDirection = parsedData["lighting_direction"] as? String
    let colorTemperature = parsedData["color_temperature"] as? String
    let composition = parsedData["composition"] as? String

    print("Mood: \(mood ?? "")")
    print("Texture Details: \(textureDetails ?? "")")
    print("Camera Angle: \(cameraAngle ?? "")")
    print("Subject Pose: \(subjectPose ?? "")")
}
```

## Advanced Usage

### Creating Custom Analyzers

Implement the `ImageAnalyzer` protocol to create your own image analysis service:

```swift
class CustomImageAnalyzer: ImageAnalyzer {
    var name: String { "Custom Vision API" }

    func analyze(
        _ input: ImageInput,
        configuration: ImageAnalysisConfiguration
    ) async throws -> ImageAnalysisResult {
        // Your custom implementation here
        // Load image data using ImageAnalyzerUtilities.loadImageData(from: input)

        // Process the image with your service

        // Return result
        let metadata = AnalysisMetadata(
            mimeType: input.mimeType,
            imageSize: imageData.count,
            analyzerName: name,
            processingTime: processingTime
        )

        return ImageAnalysisResult(
            rawResponse: responseText,
            parsedData: parsedJson,
            metadata: metadata
        )
    }
}
```

### Error Handling

The package provides comprehensive error handling:

```swift
do {
    let result = try await analyzer.analyze(fileURL: imageURL)
} catch let error as ImageAnalysisError {
    switch error {
    case .invalidImageData:
        print("Invalid image data provided")
    case .unsupportedImageFormat(let format):
        print("Unsupported format: \(format)")
    case .apiError(let statusCode, let message):
        print("API error \(statusCode): \(message)")
    case .authenticationError(let message):
        print("Authentication failed: \(message)")
    case .networkError(let underlyingError):
        print("Network error: \(underlyingError.localizedDescription)")
    case .parsingError(let message):
        print("Failed to parse response: \(message)")
    case .unknown(let underlyingError):
        print("Unknown error: \(underlyingError.localizedDescription)")
    }
} catch {
    print("Unexpected error: \(error.localizedDescription)")
}
```

## API Reference

### ImageAnalyzer Protocol

```swift
protocol ImageAnalyzer {
    var name: String { get }
    func analyze(_ input: ImageInput, configuration: ImageAnalysisConfiguration) async throws -> ImageAnalysisResult
    func analyze(_ input: ImageInput) async throws -> ImageAnalysisResult
}
```

### Key Types

- **`ImageInput`**: Enum representing different types of image input
- **`ImageAnalysisConfiguration`**: Configuration for analysis requests
- **`ImageAnalysisResult`**: Result of an analysis operation
- **`AnalysisMetadata`**: Metadata about the analysis
- **`ImageAnalysisError`**: Error types with localized descriptions

### GeminiImageAnalyzer

```swift
class GeminiImageAnalyzer: ImageAnalyzer {
    init(apiKey: String)
    init(apiKey: String, session: URLSession)

    // Convenience methods
    static func youtubeThumbnailAnalyzer(apiKey: String) -> GeminiImageAnalyzer
    static func comprehensiveImageAnalyzer(apiKey: String) -> GeminiImageAnalyzer
    static func youtubeThumbnailConfiguration() -> ImageAnalysisConfiguration
    static func comprehensiveImageConfiguration() -> ImageAnalysisConfiguration
}
```

## Requirements

- iOS 15.0+ / macOS 12.0+ / tvOS 15.0+ / watchOS 8.0+
- Swift 5.9+
- Xcode 14.0+

## License

MIT License - see LICENSE file for details.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Testing

Run the test suite:

```bash
swift test
```

Or in Xcode:
- Product > Test
- Or press `Cmd + U`
