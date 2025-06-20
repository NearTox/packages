// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.flutter.packages.interactive_media_ads

import com.google.ads.interactivemedia.v3.api.BaseDisplayContainer
import com.google.ads.interactivemedia.v3.api.CompanionAdSlot

/**
 * ProxyApi implementation for [com.google.ads.interactivemedia.v3.api.BaseDisplayContainer].
 *
 * <p>This class may handle instantiating native object instances that are attached to a Dart
 * instance or handle method calls on the associated native class or an instance of that class.
 */
class BaseDisplayContainerProxyApi(override val pigeonRegistrar: ProxyApiRegistrar) :
    PigeonApiBaseDisplayContainer(pigeonRegistrar) {
  override fun setCompanionSlots(
      pigeon_instance: BaseDisplayContainer,
      companionSlots: List<CompanionAdSlot>?
  ) {
    return pigeon_instance.setCompanionSlots(companionSlots)
  }
}
