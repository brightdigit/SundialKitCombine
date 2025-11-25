//
//  ConnectivityObserver+SessionLifecycle.swift
//  SundialKitCombine
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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

  // MARK: - ConnectivitySessionDelegate - Session Lifecycle

  @MainActor
  extension ConnectivityObserver {
    /// Handles session activation completion.
    ///
    /// Called when the connectivity session completes its activation process.
    /// Updates the observer's published state properties and emits an event through
    /// the `activationCompleted` publisher.
    ///
    /// - Parameters:
    ///   - session: The connectivity session that completed activation
    ///   - state: The activation state after completion
    ///   - error: Optional error if activation failed
    nonisolated public func session(
      _ session: any ConnectivitySession,
      activationDidCompleteWith state: ActivationState,
      error: (any Error)?
    ) {
      // Extract values before crossing isolation boundary
      let isReachable = session.isReachable
      let isPairedAppInstalled = session.isPairedAppInstalled
      #if os(iOS)
        let isPaired = session.isPaired
      #endif

      Task { @MainActor in
        self.activationState = state
        self.activationError = error
        self.isReachable = isReachable
        self.isPairedAppInstalled = isPairedAppInstalled
        #if os(iOS)
          self.isPaired = isPaired
        #endif

        // Publish activation completion event
        if let error = error {
          self.activationCompleted.send(.failure(error))
        } else {
          self.activationCompleted.send(.success(state))
        }
      }
    }

    /// Handles when session becomes inactive.
    ///
    /// Called when the connectivity session transitions to an inactive state.
    /// Updates the observer's activation state to reflect the session's new state.
    ///
    /// - Parameter session: The connectivity session that became inactive
    nonisolated public func sessionDidBecomeInactive(_ session: any ConnectivitySession) {
      // Extract value before crossing isolation boundary
      let activationState = session.activationState

      Task { @MainActor in
        self.activationState = activationState
      }
    }

    /// Handles session deactivation.
    ///
    /// Called when the connectivity session is deactivated.
    /// Updates the observer's activation state to reflect the session's new state.
    ///
    /// - Parameter session: The connectivity session that was deactivated
    nonisolated public func sessionDidDeactivate(_ session: any ConnectivitySession) {
      // Extract value before crossing isolation boundary
      let activationState = session.activationState

      Task { @MainActor in
        self.activationState = activationState
      }
    }
  }
#endif
