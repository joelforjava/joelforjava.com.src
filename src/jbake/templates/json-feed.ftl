<#--  <#ftl output_format="JSON">  -->
{
    "version": "https://jsonfeed.org/version/1",
    "title": "Joel for Java",
    "home_page_url": "${config.site_host}",
    "feed_url": "${config.site_host}/feed.json",
    "description": "A site for all things Java",
    <#if (published_posts)??>
    "items": [
        <#list published_posts as post>
        {
            "id": "${config.site_host}/${post.uri}",
            "title": "<#escape x as x?xml>${post.title}</#escape>",
            "url": "${config.site_host}/${post.uri}"
            "date_published": "${post.date?string('yyyy-MM-dd\'T\'HH:mm:ssZ')}",
            "content_html": "<#escape x as x?xml>${post.body?keep_before_last('<!--more-->')}</#escape>",
            "tags": [<#list post.tags as tag> "${tag}"<#sep>, </#sep> </#list>]
        }<#sep>, </#sep>
        </#list>
    ]
    </#if>
}
<#--  </#ftl>  -->