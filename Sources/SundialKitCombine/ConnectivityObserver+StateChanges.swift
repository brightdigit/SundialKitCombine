//
//  ConnectivityObserver+StateChanges.swift
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

  // MARK: - ConnectivitySessionDelegate - State Changes

  @MainActor
  extension ConnectivityObserver {
    /// Handles when session reachability changes.
    ///
    /// Called when the reachability status of the counterpart device changes.
    /// Updates the observer's `isReachable` property.
    ///
    /// - Parameter session: The connectivity session with updated reachability
    nonisolated public func sessionReachabilityDidChange(_ session: any ConnectivitySession) {
      // Extract value before crossing isolation boundary
      let isReachable = session.isReachable

      Task { @MainActor in
        self.isReachable = isReachable
      }
    }

    /// Handles companion device state changes.
    ///
    /// Called when the pairing status of the counterpart device changes.
    /// Updates the observer's `isPairedAppInstalled` and `isPaired` properties.
    ///
    /// - Parameter session: The connectivity session with updated companion state
    nonisolated public func sessionCompanionStateDidChange(_ session: any ConnectivitySession) {
      // Extract values before crossing isolation boundary
      let isPairedAppInstalled = session.isPairedAppInstalled
      #if os(iOS)
        let isPaired = session.isPaired
      #endif

      Task { @MainActor in
        self.isPairedAppInstalled = isPairedAppInstalled
        #if os(iOS)
          self.isPaired = isPaired
        #endif
      }
    }
  }
#endif
