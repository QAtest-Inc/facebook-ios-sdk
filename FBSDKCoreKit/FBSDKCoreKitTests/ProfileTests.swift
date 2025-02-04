// Copyright (c) 2014-present, Facebook, Inc. All rights reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import FBSDKCoreKit
import TestTools
import XCTest

class ProfileTests: XCTestCase {

  var store = UserDefaultsSpy()
  var notificationCenter = TestNotificationCenter()
  let settings = TestSettings()

  override func setUp() {
    super.setUp()
    TestAccessTokenWallet.reset()
    Profile.configure(
      store: store,
      accessTokenProvider: TestAccessTokenWallet.self,
      notificationCenter: notificationCenter,
      settings: settings
    )
  }

  override func tearDown() {
    super.tearDown()

    Profile.reset()
    TestAccessTokenWallet.reset()
  }

  func testDefaultStore() {
    Profile.reset()
    XCTAssertNil(
      Profile.store,
      "Should not have a default data store"
    )
  }

  func testConfiguringWithStore() {
    XCTAssertTrue(
      Profile.store === store,
      "Should be able to set a persistent data store"
    )
  }

  func testConfiguringWithNotificationCenter() {
    XCTAssertTrue(
      Profile.notificationCenter === notificationCenter,
      "Should be able to set a Notification Posting"
    )
  }

  func testDefaultAccessTokenProvider() {
    Profile.reset()
    XCTAssertNil(
      Profile.accessTokenProvider,
      "Should not have a default access token provider"
    )
  }

  func testConfiguringWithTokenProvider() {
    XCTAssertTrue(
      Profile.accessTokenProvider is TestAccessTokenWallet.Type,
      "Should be able to set a token wallet"
    )
  }

  func testDefaultSettings() {
    Profile.reset()
    XCTAssertNil(
      Profile.settings,
      "Should not have default settings"
    )
  }

  func testConfiguringWithSettings() {
    XCTAssertTrue(
      Profile.settings === settings,
      "Should be able to set settings"
    )
  }

  func testHashability() {
    let profile = SampleUserProfiles.createValid()
    let profile2 = SampleUserProfiles.createValid(userID: name)

    XCTAssertEqual(
      profile.hash,
      profile.hash,
      "Hashed profiles should be consistent"
    )
    XCTAssertNotEqual(
      profile.hash,
      profile2.hash,
      "Hashed profiles should be unique"
    )
  }

  func testFetchingCachedProfile() {
    _ = Profile.fetchCachedProfile()

    XCTAssertEqual(
      store.capturedObjectRetrievalKey,
      "com.facebook.sdk.FBSDKProfile.currentProfile",
      "Fetching a cached profile should query the store with the expected retrieval key"
    )
  }
}
