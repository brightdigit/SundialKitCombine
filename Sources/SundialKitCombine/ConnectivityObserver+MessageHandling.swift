//
//  ConnectivityObserver+MessageHandling.swift
//  SundialKitCombine
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#if canImport(Combine)
  public import Combine
  public import Foundation
  public import SundialKitConnectivity
  public import SundialKitCore

  #if canImport(os.log)
    import os.log
  #endif

  // MARK: - ConnectivitySessionDelegate - Message Handling

  @MainActor
  extension ConnectivityObserver {
    /// Handles received message with reply handler.
    ///
    /// Called when a dictionary message is received from the counterpart device.
    /// Publishes the message through both raw and typed publishers if a decoder is available.
    ///
    /// - Parameters:
    ///   - session: The connectivity session that received the message
    ///   - message: The dictionary message received
    ///   - replyHandler: Handler to send a reply back to the sender
    nonisolated public func session(
      _ session: any ConnectivitySession,
      didReceiveMessage message: ConnectivityMessage,
      replyHandler: @escaping @Sendable ([String: any Sendable]) -> Void
    ) {
      Task { @MainActor in
        // Send to raw publisher
        let result = ConnectivityReceiveResult(message: message, context: .replyWith(replyHandler))
        self.messageReceived.send(result)

        // Decode and send to typed publisher
        if let decoder = self.messageDecoder {
          do {
            let decoded = try decoder.decode(message)
            self.typedMessageReceived.send(decoded)
          } catch {
            // Decoding failed - log but don't crash (raw publisher still gets the message)
            if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
              SundialLogger.combine.error("Failed to decode message: \(String(describing: error))")
            }
          }
        }
      }
    }

    /// Handles received application context.
    ///
    /// Called when an application context update is received from the counterpart device.
    /// Publishes the context through both raw and typed publishers if a decoder is available.
    ///
    /// - Parameters:
    ///   - session: The connectivity session that received the context
    ///   - applicationContext: The application context dictionary received
    ///   - error: Optional error if context reception failed
    nonisolated public func session(
      _ session: any ConnectivitySession,
      didReceiveApplicationContext applicationContext: ConnectivityMessage,
      error: (any Error)?
    ) {
      Task { @MainActor in
        // Send to raw publisher
        let result = ConnectivityReceiveResult(
          message: applicationContext, context: .applicationContext
        )
        self.messageReceived.send(result)

        // Decode and send to typed publisher
        if let decoder = self.messageDecoder {
          do {
            let decoded = try decoder.decode(applicationContext)
            self.typedMessageReceived.send(decoded)
          } catch {
            // Decoding failed - log but don't crash (raw publisher still gets the message)
            if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
              SundialLogger.combine.error(
                "Failed to decode application context: \(String(describing: error))"
              )
            }
          }
        }
      }
    }

    /// Handles received binary message data with reply handler.
    ///
    /// Called when binary message data is received from the counterpart device.
    /// Attempts to decode using the message decoder if available.
    ///
    /// - Parameters:
    ///   - session: The connectivity session that received the data
    ///   - messageData: The binary message data received
    ///   - replyHandler: Handler to send a binary reply back to the sender
    nonisolated public func session(
      _ session: any ConnectivitySession,
      didReceiveMessageData messageData: Data,
      replyHandler: @escaping @Sendable (Data) -> Void
    ) {
      Task { @MainActor in
        // Decode and send to typed publisher
        if let decoder = self.messageDecoder {
          do {
            let decoded = try decoder.decodeBinary(messageData)
            self.typedMessageReceived.send(decoded)
          } catch {
            // Decoding failed - log the error
            if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
              SundialLogger.combine.error(
                "Failed to decode binary message: \(String(describing: error))"
              )
            }
          }
        }

        // IMPORTANT: Must call reply handler to complete the send operation on sender's side
        // Send empty Data as acknowledgment since we don't have a reply payload
        // replyHandler(Data())
      }
    }

    /// Handles a queued dictionary received via `transferUserInfo(_:)`.
    ///
    /// Queued delivery has no reply handler; the payload is surfaced through the
    /// raw publisher (as background/application-context) and the typed publisher.
    ///
    /// - Parameters:
    ///   - session: The connectivity session that received the user info
    ///   - userInfo: The received dictionary
    nonisolated public func session(
      _ session: any ConnectivitySession,
      didReceiveUserInfo userInfo: ConnectivityMessage
    ) {
      Task { @MainActor in
        // Send to raw publisher
        let result = ConnectivityReceiveResult(message: userInfo, context: .applicationContext)
        self.messageReceived.send(result)

        // Decode and send to typed publisher
        if let decoder = self.messageDecoder {
          do {
            let decoded = try decoder.decode(userInfo)
            self.typedMessageReceived.send(decoded)
          } catch {
            // Decoding failed - log but don't crash (raw publisher still gets the message)
            if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
              SundialLogger.combine.error("Failed to decode user info: \(String(describing: error))")
            }
          }
        }
      }
    }

    /// Handles a queued file's contents received via `transferFile(_:metadata:)`.
    ///
    /// The file is read into `Data` before this is called; the binary partner of
    /// `transferUserInfo`, it is decoded and published to the typed publisher.
    ///
    /// - Parameters:
    ///   - session: The connectivity session that received the file
    ///   - fileData: The contents of the received file
    ///   - metadata: Optional dictionary that accompanied the file
    nonisolated public func session(
      _ session: any ConnectivitySession,
      didReceiveFile fileData: Data,
      metadata: ConnectivityMessage?
    ) {
      Task { @MainActor in
        // Decode and send to typed publisher
        if let decoder = self.messageDecoder {
          do {
            let decoded = try decoder.decodeBinary(fileData)
            self.typedMessageReceived.send(decoded)
          } catch {
            // Decoding failed - log the error
            if #available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *) {
              SundialLogger.combine.error(
                "Failed to decode received file: \(String(describing: error))"
              )
            }
          }
        }
      }
    }
  }
#endif
