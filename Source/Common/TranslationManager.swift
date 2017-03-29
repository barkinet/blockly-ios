/*
 * Copyright 2017 Google Inc. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

/**
 Object responsible for managing translation strings within Blockly.

 This class is designed as a singleton instance, accessible via `TranslationManager.shared`.
 */
@objc(BKYTranslationManager)
public class TranslationManager: NSObject {
  // MARK: - Properties

  /// Shared instance.
  public static var shared: TranslationManager = {
    let manager = TranslationManager()
    let bundle = Bundle(for: TranslationManager.self)

    // Load default files, and prefix all values with "bky_"
    do {
      try manager.loadTranslations(
        withPrefix: "bky_", jsonPath: "bky_constants.json", bundle: bundle)
      try manager.loadTranslations(
        withPrefix: "bky_", jsonPath: "bky_messages.json", bundle: bundle)
      try manager.loadSynonyms(withPrefix: "bky_", jsonPath: "bky_synonyms.json", bundle: bundle)
    } catch let error {
      bky_debugPrint("Could not load default files for TranslationManager: \(error)")
    }

    return manager
  }()

  /// Dictionary of translation keys mapped to translation values.
  fileprivate var _translations = [String: String]()

  /// Dictionary of synonym keys mapped to message keys.
  fileprivate var _synonyms = [String: String]()

  // MARK: - Initializers

  /**
   A singleton instance for this class is accessible via `TranslationManager.shared.`
   */
  internal override init() {
  }

  // MARK: - Loading Data

  /**
   Loads translations from a JSON file, with a given prefix. Any existing translations are
   overwritten by those from this file.
   */
  public func loadTranslations(
    withPrefix prefix: String, jsonPath: String, bundle: Bundle? = nil) throws {

    let aBundle = bundle ?? Bundle.main
    guard let path = aBundle.path(forResource: jsonPath, ofType: nil) else {
      throw BlocklyError(.fileNotFound, "Could not find \"\(jsonPath)\" in bundle [\(aBundle)].")
    }

    let jsonString = try String(contentsOfFile: path, encoding: String.Encoding.utf8)

    let json = try JSONHelper.makeJSONDictionary(string: jsonString)

    for (key, value) in json {
      if key == "@metadata" {
        // Skip this value.
      } else if let stringValue = value as? String {
        // Store the translation, but keyed with the given prefix
        _translations[(prefix + key).lookupKey()] = stringValue
      } else {
        bky_debugPrint("Unrecognized value type ('\(type(of: value))') for key ('\(key)').")
      }
    }
  }

  public func loadTranslations(_ translations: [String: String]) {
    // Overwrite existing translations
    for (key, value) in translations {
      _translations[key.lookupKey()] = value
    }
  }

  /**
   Loads synonyms from a JSON file, with a given prefix. Any existing synonym mappings are
   overwritten by those from this file.
   */
  public func loadSynonyms(
    withPrefix prefix: String, jsonPath: String, bundle: Bundle? = nil) throws {

    let aBundle = bundle ?? Bundle.main
    guard let path = aBundle.path(forResource: jsonPath, ofType: nil) else {
      throw BlocklyError(.fileNotFound, "Could not find \"\(jsonPath)\" in bundle [\(aBundle)].")
    }

    let jsonString = try String(contentsOfFile: path, encoding: String.Encoding.utf8)

    let json = try JSONHelper.makeJSONDictionary(string: jsonString)

    for (key, value) in json {
      if let stringValue = value as? String {
        // Store the synonym with the given prefix
        _synonyms[(prefix + key).lookupKey()] = (prefix + stringValue).lookupKey()
      } else {
        bky_debugPrint("Unrecognized value type ('\(type(of: value))') for key ('\(key)').")
      }
    }
  }

  public func loadSynonyms(_ synonyms: [String: String]) {
    // Overwrite existing synonym values
    for (key, value) in synonyms {
      _synonyms[key.lookupKey()] = value
    }
  }

  // MARK: - Translation

  /**
   Returns a message translation for a given key. It prioritizes look-up from the translation table,
   before falling back to the synonyms table. If no message or associated synonym
   message could be found for the given key, then returns `nil`.
 
   - parameter key: The key to use to look for a message or associated synonym message.
   - returns: The message or associated synonym message for the given `key`. If neither exist, then
   `nil` is returned.
  */
  public func translation(forKey key: String) -> String? {
    let lookupKey = key.lookupKey()

    if let value = _translations[lookupKey] {
      return value
    } else if let synonym = _synonyms[lookupKey],
      let value = _translations[synonym] {
      return value
    }
    return nil
  }
}

fileprivate extension String {
  func lookupKey() -> String {
    // Simply lookup by lowercasing all keys
    return self.lowercased()
  }
}
