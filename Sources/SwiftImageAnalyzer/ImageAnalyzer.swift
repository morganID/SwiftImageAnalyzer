import Foundation

// MARK: - Image Analyzer Protocol

/// Protocol defining the interface for image analysis services
public protocol ImageAnalyzer {
    /// The name of this analyzer
    var name: String { get }

    /// Analyze an image with the given configuration
    /// - Parameters:
    ///   - input: The image input to analyze
    ///   - configuration: Configuration for the analysis
    /// - Returns: Analysis result
    /// - Throws: ImageAnalysisError if analysis fails
    func analyze(
        _ input: ImageInput,
        configuration: ImageAnalysisConfiguration
    ) async throws -> ImageAnalysisResult

    /// Analyze an image with default configuration
    /// - Parameter input: The image input to analyze
    /// - Returns: Analysis result
    /// - Throws: ImageAnalysisError if analysis fails
    func analyze(_ input: ImageInput) async throws -> ImageAnalysisResult
}

// MARK: - Default Implementation

extension ImageAnalyzer {
    /// Default implementation that uses ImageAnalysisConfiguration.default
    public func analyze(_ input: ImageInput) async throws -> ImageAnalysisResult {
        try await analyze(input, configuration: .default)
    }
}

// MARK: - Helper Extensions

extension ImageAnalyzer {
    /// Analyze an image from file URL
    /// - Parameters:
    ///   - fileURL: URL of the image file
    ///   - configuration: Configuration for the analysis
    /// - Returns: Analysis result
    /// - Throws: ImageAnalysisError if analysis fails
    public func analyze(
        fileURL: URL,
        configuration: ImageAnalysisConfiguration = .default
    ) async throws -> ImageAnalysisResult {
        try await analyze(.fileURL(fileURL), configuration: configuration)
    }

    /// Analyze an image from remote URL
    /// - Parameters:
    ///   - remoteURL: URL of the remote image
    ///   - configuration: Configuration for the analysis
    /// - Returns: Analysis result
    /// - Throws: ImageAnalysisError if analysis fails
    public func analyze(
        remoteURL: URL,
        configuration: ImageAnalysisConfiguration = .default
    ) async throws -> ImageAnalysisResult {
        try await analyze(.remoteURL(remoteURL), configuration: configuration)
    }

    /// Analyze an image from Data
    /// - Parameters:
    ///   - data: Image data
    ///   - mimeType: MIME type of the image
    ///   - configuration: Configuration for the analysis
    /// - Returns: Analysis result
    /// - Throws: ImageAnalysisError if analysis fails
    public func analyze(
        data: Data,
        mimeType: String,
        configuration: ImageAnalysisConfiguration = .default
    ) async throws -> ImageAnalysisResult {
        try await analyze(.data(data, mimeType: mimeType), configuration: configuration)
    }
}
