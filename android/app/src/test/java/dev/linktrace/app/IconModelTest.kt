package dev.linktrace.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class IconModelTest {
  private val png = "data:image/png;base64,iVBORw0KGgo="

  @Test fun iconRoundTripsAndIsOmittedWhenEmpty() {
    val d = AtlasData(accounts = listOf(Account("a1", "微信", icon = png), Account("a2", "QQ")))
    val text = encodeAtlas(d)
    assertTrue(text.contains("\"icon\":\"$png\""))
    assertEquals(1, Regex("\"icon\"").findAll(text).count())
    val back = decodeAtlas(text)
    assertEquals(png, back.accounts[0].icon)
    assertNull(back.accounts[1].icon)
    assertEquals(Merge.sig(d), Merge.sig(back))
  }

  @Test fun emptyIconBecomesNull() {
    val d = decodeAtlas("""{"identities":[],"accounts":[{"id":"x","name":"n","icon":""}],"deleted":{}}""")
    assertNull(d.accounts[0].icon)
    assertTrue(!encodeAtlas(d).contains("icon"))
  }

  @Test fun appStoreMapping() {
    assertEquals("支付宝", appStoreName("支付宝-你的AI生活伙伴"))
    assertEquals("Notion", appStoreName("Notion - notes, docs, tasks"))
    assertEquals("X-Ray", appStoreName("X-Ray"))   // only 1 char before the dash: keep
    assertEquals("微信", appStoreName("微信"))
    assertEquals("社交", appStoreCategory("Social Networking", listOf("社交")))
    assertEquals("支付金融", appStoreCategory("Lifestyle", listOf("生活", "财务"), listOf("6012", "6015")))
    assertEquals("娱乐", appStoreCategory("Photo & Video", emptyList()))
    assertEquals("出行", appStoreCategory("Navigation", emptyList()))
    assertEquals("工具", appStoreCategory("Productivity", listOf("效率")))
    val hits = parseAppStore("""{"resultCount":1,"results":[{"trackName":"微信","sellerUrl":"http://www.weixin.qq.com/x","primaryGenreName":"Social Networking",
      "genres":["社交"],"genreIds":["6005"],"artworkUrl100":"https://a/100x100bb.jpg"}]}""")
    assertEquals(1, hits.size)
    assertEquals("weixin.qq.com", hits[0].domain)
    assertEquals("社交", hits[0].category)
    assertEquals("https://a/256x256bb.jpg", hits[0].artwork)
    assertTrue(appStoreURL("微 信").startsWith("https://itunes.apple.com/search?term=%E5%BE%AE+%E4%BF%A1&country=cn&entity=software&limit=8"))
    assertEquals(emptyList<AppHit>(), parseAppStore("not json"))
  }
}
