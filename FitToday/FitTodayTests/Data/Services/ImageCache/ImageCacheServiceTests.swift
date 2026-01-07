//
//  ImageCacheServiceTests.swift
//  FitTodayTests
//
//  Created by AI on 07/01/26.
//

import XCTest
import Foundation
import UIKit
@testable import FitToday

final class ImageCacheServiceTests: XCTestCase {
  
  // MARK: - Helper Properties
  
  var testConfig: ImageCacheConfiguration!
  var testURL: URL!
  var testURL2: URL!
  var testURL3: URL!
  
  override func setUp() {
    super.setUp()
    self.testConfig = ImageCacheConfiguration.test
    self.testURL = URL(string: "https://example.com/image1.jpg")!
    self.testURL2 = URL(string: "https://example.com/image2.jpg")!
    self.testURL3 = URL(string: "https://example.com/image3.jpg")!
  }
  
  override func tearDown() {
    try? FileManager.default.removeItem(at: testConfig.cacheDirectory)
    super.tearDown()
  }
  
  // MARK: - Configuration Tests
  
  func testDefaultConfiguration() {
    let config = ImageCacheConfiguration.default
    
    XCTAssertEqual(config.maxDiskSize, 500 * 1024 * 1024) // 500 MB
    XCTAssertEqual(config.maxMemorySize, 50 * 1024 * 1024) // 50 MB
    XCTAssertEqual(config.prefetchConcurrency, 5)
  }
  
  func testTestConfiguration() {
    let config = ImageCacheConfiguration.test
    
    XCTAssertEqual(config.maxDiskSize, 10 * 1024 * 1024) // 10 MB
    XCTAssertEqual(config.maxMemorySize, 5 * 1024 * 1024) // 5 MB
    XCTAssertEqual(config.prefetchConcurrency, 3)
  }
  
  // MARK: - DiskImageCache Tests
  
  func testDiskCacheCreatesDirectory() async {
    let cache = DiskImageCache(configuration: testConfig)
    let fileManager = FileManager.default
    
    let exists = fileManager.fileExists(atPath: testConfig.cacheDirectory.path)
    XCTAssertTrue(exists)
  }
  
  func testDiskCacheSaveAndRetrieve() async throws {
    let cache = DiskImageCache(configuration: testConfig)
    
    // Criar dados de teste
    let testData = "Test Image Data".data(using: .utf8)!
    
    // Salvar
    try await cache.save(testData, for: testURL)
    
    // Recuperar
    let retrievedData = await cache.data(for: testURL)
    
    XCTAssertNotNil(retrievedData)
    XCTAssertEqual(retrievedData, testData)
  }
  
  func testDiskCacheMiss() async {
    let cache = DiskImageCache(configuration: testConfig)
    
    let data = await cache.data(for: testURL)
    XCTAssertNil(data)
  }
  
  func testDiskCacheTotalSize() async throws {
    let cache = DiskImageCache(configuration: testConfig)
    
    // Salvar múltiplos arquivos
    let data1 = Data(repeating: 0, count: 1024) // 1 KB
    let data2 = Data(repeating: 1, count: 2048) // 2 KB
    
    try await cache.save(data1, for: testURL)
    try await cache.save(data2, for: testURL2)
    
    let totalSize = await cache.totalSize()
    
    // Deve ser aproximadamente 3 KB (pode ter overhead do filesystem)
    XCTAssertGreaterThanOrEqual(totalSize, 3072)
    XCTAssertLessThan(totalSize, 4096) // Com margem para overhead
  }
  
  func testDiskCacheClearAll() async throws {
    let cache = DiskImageCache(configuration: testConfig)
    
    // Salvar dados
    let testData = "Test".data(using: .utf8)!
    try await cache.save(testData, for: testURL)
    
    // Verificar que existe
    var data = await cache.data(for: testURL)
    XCTAssertNotNil(data)
    
    // Limpar
    await cache.clearAll()
    
    // Verificar que foi removido
    data = await cache.data(for: testURL)
    XCTAssertNil(data)
    
    let size = await cache.totalSize()
    XCTAssertEqual(size, 0)
  }
  
  func testDiskCacheLRUEviction() async throws {
    // Criar config com limite pequeno para testar eviction
    let smallConfig = ImageCacheConfiguration(
      maxDiskSize: 3000, // 3 KB
      maxMemorySize: testConfig.maxMemorySize,
      cacheDirectory: testConfig.cacheDirectory,
      prefetchConcurrency: testConfig.prefetchConcurrency
    )
    
    let cache = DiskImageCache(configuration: smallConfig)
    
    // Salvar primeiro arquivo (1 KB)
    let data1 = Data(repeating: 0, count: 1024)
    try await cache.save(data1, for: testURL)
    
    // Pequeno delay para garantir timestamps diferentes
    try await Task.sleep(nanoseconds: 100_000_000) // 0.1s
    
    // Salvar segundo arquivo (1 KB)
    let data2 = Data(repeating: 1, count: 1024)
    try await cache.save(data2, for: testURL2)
    
    try await Task.sleep(nanoseconds: 100_000_000)
    
    // Salvar terceiro arquivo (1.5 KB) - deve causar eviction do primeiro
    let data3 = Data(repeating: 2, count: 1536)
    try await cache.save(data3, for: testURL3)
    
    // Primeiro arquivo deve ter sido removido (LRU)
    let retrieved1 = await cache.data(for: testURL)
    XCTAssertNil(retrieved1)
    
    // Segundo e terceiro devem existir
    let retrieved2 = await cache.data(for: testURL2)
    let retrieved3 = await cache.data(for: testURL3)
    XCTAssertNotNil(retrieved2)
    XCTAssertNotNil(retrieved3)
  }
  
  // MARK: - ImageCacheService Tests
  
  func testCacheMiss() async {
    let service = ImageCacheService(configuration: testConfig)
    
    let image = await service.cachedImage(for: testURL)
    XCTAssertNil(image)
  }
  
  func testDiskCacheHit() async throws {
    let service = ImageCacheService(configuration: testConfig)
    
    // Criar imagem de teste (1x1 pixel vermelho)
    let testImage = createTestImage()
    guard let imageData = testImage.pngData() else {
      XCTFail("Failed to create test image data")
      return
    }
    
    // Salvar diretamente no disk cache
    let diskCache = DiskImageCache(configuration: testConfig)
    try await diskCache.save(imageData, for: testURL)
    
    // Recuperar via service
    let cachedImage = await service.cachedImage(for: testURL)
    
    XCTAssertNotNil(cachedImage)
    XCTAssertEqual(cachedImage?.size, testImage.size)
  }
  
  func testClearCache() async throws {
    let service = ImageCacheService(configuration: testConfig)
    
    // Adicionar dados ao cache
    let testImage = createTestImage()
    guard let imageData = testImage.pngData() else {
      XCTFail("Failed to create test image data")
      return
    }
    
    let diskCache = DiskImageCache(configuration: testConfig)
    try await diskCache.save(imageData, for: testURL)
    
    // Verificar que existe
    var cached = await service.cachedImage(for: testURL)
    XCTAssertNotNil(cached)
    
    // Limpar
    await service.clearCache()
    
    // Verificar que foi removido
    cached = await service.cachedImage(for: testURL)
    XCTAssertNil(cached)
    
    let size = await service.cacheSize()
    XCTAssertEqual(size, 0)
  }
  
  func testCacheSize() async throws {
    let service = ImageCacheService(configuration: testConfig)
    
    // Inicialmente deve ser zero
    var size = await service.cacheSize()
    XCTAssertEqual(size, 0)
    
    // Adicionar dados
    let testData = Data(repeating: 0, count: 5000)
    let diskCache = DiskImageCache(configuration: testConfig)
    try await diskCache.save(testData, for: testURL)
    
    // Tamanho deve aumentar
    size = await service.cacheSize()
    XCTAssertGreaterThan(size, 0)
  }
  
  func testPrefetchMultipleURLs() async {
    let service = ImageCacheService(configuration: testConfig)
    
    // URLs de teste (não vão fazer download real, mas testar a lógica)
    let urls = [testURL!, testURL2!, testURL3!]
    
    // Prefetch não deve crashar mesmo com URLs inválidas
    await service.prefetchImages(urls)
    
    // Teste passa se não crashar
    XCTAssertTrue(true)
  }
  
  func testThreadSafety() async throws {
    let service = ImageCacheService(configuration: testConfig)
    
    // Preparar dados de teste
    let testImage = createTestImage()
    guard let imageData = testImage.pngData() else {
      XCTFail("Failed to create test image data")
      return
    }
    
    let diskCache = DiskImageCache(configuration: testConfig)
    try await diskCache.save(imageData, for: testURL)
    
    // Acessar concorrentemente
    await withTaskGroup(of: UIImage?.self) { group in
      for _ in 0..<10 {
        group.addTask {
          await service.cachedImage(for: self.testURL)
        }
      }
      
      var results: [UIImage?] = []
      for await result in group {
        results.append(result)
      }
      
      // Todos devem retornar a imagem
      XCTAssertEqual(results.count, 10)
      XCTAssertTrue(results.allSatisfy { $0 != nil })
    }
  }
  
  // MARK: - MockImageCacheService Tests
  
  func testMockCacheService() async throws {
    let mock = MockImageCacheService()
    
    // Inicialmente vazio
    var image = await mock.cachedImage(for: testURL)
    XCTAssertNil(image)
    
    // Cachear
    try await mock.cacheImage(from: testURL)
    
    // Deve retornar
    image = await mock.cachedImage(for: testURL)
    XCTAssertNotNil(image)
  }
  
  func testMockCacheServiceError() async {
    let mock = MockImageCacheService()
    mock.shouldThrowError = true
    
    do {
      try await mock.cacheImage(from: testURL)
      XCTFail("Should have thrown error")
    } catch {
      // Esperado
      XCTAssertTrue(error is ImageCacheError)
    }
  }
  
  func testMockPrefetchTracking() async {
    let mock = MockImageCacheService()
    
    let urls = [testURL!, testURL2!, testURL3!]
    await mock.prefetchImages(urls)
    
    XCTAssertEqual(mock.prefetchedURLs.count, 3)
    XCTAssertTrue(mock.prefetchedURLs.contains(testURL))
    XCTAssertTrue(mock.prefetchedURLs.contains(testURL2))
    XCTAssertTrue(mock.prefetchedURLs.contains(testURL3))
  }
  
  func testMockClearCache() async throws {
    let mock = MockImageCacheService()
    
    try await mock.cacheImage(from: testURL)
    await mock.prefetchImages([testURL2])
    
    XCTAssertGreaterThan(mock.cachedImages.count, 0)
    XCTAssertGreaterThan(mock.prefetchedURLs.count, 0)
    
    await mock.clearCache()
    
    XCTAssertTrue(mock.cachedImages.isEmpty)
    XCTAssertTrue(mock.prefetchedURLs.isEmpty)
  }
  
  // MARK: - Helper Methods
  
  private func createTestImage() -> UIImage {
    // Criar imagem 1x1 pixel vermelho
    let size = CGSize(width: 1, height: 1)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
      UIColor.red.setFill()
      context.fill(CGRect(origin: .zero, size: size))
    }
  }
}

// MARK: - Error Tests

final class ImageCacheErrorTests: XCTestCase {
  
  func testErrorDescriptions() {
    let errors: [ImageCacheError] = [
      .invalidResponse(statusCode: 404),
      .diskWriteFailed(underlying: NSError(domain: "test", code: 1)),
      .cacheSizeExceeded,
      .invalidImageData
    ]
    
    for error in errors {
      let description = error.errorDescription
      XCTAssertNotNil(description)
      XCTAssertFalse(description!.isEmpty)
    }
  }
  
  func testInvalidResponseError() {
    let error = ImageCacheError.invalidResponse(statusCode: 404)
    let description = error.errorDescription ?? ""
    
    XCTAssertTrue(description.contains("404"))
  }
}
