//
//  ParserEnums.swift
//  Ref FeedKit: https://github.com/nmdias/FeedKit
//  Caster
//
//  Created by Alex Truong on 4/26/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import Foundation

// MARK: enums

enum ParseStatus: Int {
    case parsing
    case stopped
    case aborted
    case failed
}

enum FeedPath: String {
    case FeedEntry                      = "/feed/entry"
    case FeedEntryUpdated               = "/feed/entry/updated"
    case FeedEntryID                    = "/feed/entry/id"
    case FeedEntryTitle                 = "/feed/entry/title"
    case FeedEntrySummary               = "/feed/entry/summary"
    case FeedEntryLink                  = "/feed/entry/link"
    case FeedEntryCategory              = "/feed/entry/category"
    case FeedEntryContent               = "/feed/entry/content"
    case FeedEntryRights                = "/feed/entry/rights"
    case FeedEntryName                  = "/feed/entry/im:name"
    case FeedEntryArtist                = "/feed/entry/im:artist"
    case FeedEntryImage                 = "/feed/entry/im:image"
    case FeedEntryReleaseDate           = "/feed/entry/im:releaseDate"
}

enum RSSPath: String {
    case RSSChannel                         = "/rss/channel"
    case RSSChannelTitle                    = "/rss/channel/title"
    case RSSChannelLink                     = "/rss/channel/link"
    case RSSChannelDescription              = "/rss/channel/description"
    case RSSChannelLanguage                 = "/rss/channel/language"
    case RSSChannelPubDate                  = "/rss/channel/pubDate"
    case RSSChannelLastBuildDate            = "/rss/channel/lastBuildDate"
    case RSSChannelCategory                 = "/rss/channel/category"
    case RSSChannelCopyright                = "/rss/channel/copyright"
    case RSSChannelImageURL                 = "/rss/channel/image/url"
    case RSSChannelItem                     = "/rss/channel/item"
    case RSSChannelItemTitle                = "/rss/channel/item/title"
    case RSSChannelItemLink                 = "/rss/channel/item/link"
    case RSSChannelItemDescription          = "/rss/channel/item/description"
    case RSSChannelItemAuthor               = "/rss/channel/item/author"
    case RSSChannelItemCategory             = "/rss/channel/item/category"
    case RSSChannelItemComments             = "/rss/channel/item/comments"
    case RSSChannelItemEnclosure            = "/rss/channel/item/enclosure"
    case RSSChannelItemMediaContent         = "/rss/channel/item/media:content"
    case RSSChannelItemGUID                 = "/rss/channel/item/guid"
    case RSSChannelItemPubDate              = "/rss/channel/item/pubDate"
    case RSSChannelItemSource               = "/rss/channel/item/source"
    case RSSChannelItemContent              = "/rss/channel/item/content:encoded"
    
    // itunes related
    case RSSChannelItunesSubtitle               = "/rss/channel/itunes:subtitle"
    case RSSChannelItunesCategory               = "/rss/channel/itunes:category"
    case RSSChannelItunesSummary                = "/rss/channel/itunes:summary"
    case RSSChannelItunesKeywords               = "/rss/channel/itunes:keywords"
    case RSSChannelItunesAuthor                 = "/rss/channel/itunes:author"
    case RSSChannelItemItunesAuthor             = "/rss/channel/item/itunes:author"
    case RSSChannelItemItunesImage              = "/rss/channel/item/itunes:image"
    case RSSChannelItemItunesDuration           = "/rss/channel/item/itunes:duration"
    case RSSChannelItemItunesOrder              = "/rss/channel/item/itunes:order"
    case RSSChannelItemItunesSubtitle           = "/rss/channel/item/itunes:subtitle"
    case RSSChannelItemItunesSummary            = "/rss/channel/item/itunes:summary"
    case RSSChannelItemItunesKeywords           = "/rss/channel/item/itunes:keywords"
    
    // for TED
    case RSSChannelMediaCopyright               = "/rss/channel/media:copyright"
}
