package com.joelforjava.gradle.task

import org.gradle.api.DefaultTask
import org.gradle.api.file.FileTree
import org.gradle.api.tasks.TaskAction

class CheckBadLinksTask extends DefaultTask {

    String sourceDirectory
    String contentDirectory

    @TaskAction
    def check() {
        FileTree tree = project.fileTree(dir: contentDirectory)

        FileTree filtered = tree.matching {
            include '**/*.md'
            include '**/*.html'
            include '**/*.ad'
        }

        Map pageUrls = [:]
        int total = 0
        int oldBlogTotal = 0

        // Courtesy of https://stackoverflow.com/a/15926317
        def aHrefPattern = /<a\s+(?:[^>]*?\s+)?href=(["'])(.*?)\1/
        def imgSrcPattern = /<img\s+(?:[^>]*?\s+)?src=(["'])(.*?)\1/
        // Courtesy of https://stackoverflow.com/a/23658017
        def mdHrefPattern = /\[(?<text>[^\]]*)\]\((?<link>[^\)]*)\)/
        filtered.each { element ->
            List urls = []
            element.eachLine('utf-8') { line ->
                def findHrefGroup = (line =~ aHrefPattern)
                findHrefGroup?.each { group ->
                    urls << group[-1]
                }
                def findMdHrefGroup = (line =~ mdHrefPattern)
                findMdHrefGroup?.each {
                    urls << it[-1]
                }
                def findImgSrcGroup = (line =~ imgSrcPattern)
                findImgSrcGroup?.each {
                    urls << it[-1]
                }
            }
            pageUrls[element.absolutePath] = urls
            total += urls.size()
        }
        println '--------'
        pageUrls.each { page, links ->
            println "Verifying Links found in: ${page}"
            def oldBlogLinks = links.findAll { it.isOldBlogLink() }
            if (oldBlogLinks) {
                oldBlogTotal += oldBlogLinks.size()
                oldBlogLinks.each {
                    println("\t OLD BLOG LINK -> ${it}")
                }
            }
            def externalUrls = links.findAll { ! it.isOldBlogLink() && !it.isLocalhostUrl() && ! it.isRelativeUrl() }
            externalUrls?.each { externalUrl ->
                try {
                    def check = 200 //checkUrl(externalUrl)
                    if (200 == check) {
                        println "\t \u2713 ${externalUrl}"
                    } else {
                        println "\t ! ${externalUrl} - $check"
                    }
                } catch (e) {
                    System.err.println "\t \u2716 ${externalUrl} -> $e"
                }
            }
            def relativeUrls = links.findAll { it.isRelativeUrl() }
            relativeUrls?.each { relativeUrl ->
                // TODO - cycle through all possible file extensions to find original content
                boolean isValid = false
                if (relativeUrl.startsWith('/images')) {
                    isValid = new File(sourceDirectory, "/assets$relativeUrl").canRead()
                } else {
                    isValid = new File(contentDirectory, relativeUrl.replace('html', 'md')).canRead()
                }
                if (isValid) {
                    println "\t \u2713 ${relativeUrl}"
                } else {
                    println "\t ! ${relativeUrl}"
                }
                
            }
            println '--------'
        }
        println "\n\nTotal URLS found: $total"
        println "\t $oldBlogTotal of those were old blog links"
    }

    def checkUrl(String url) {
        // Found here: https://stackoverflow.com/questions/43584382/how-to-check-if-a-url-exists-or-returns-404-using-groovy-script
        def check = new URL(url).openConnection().with {
            // requestMethod = 'HEAD'
            requestMethod = 'GET'
            connect()
            responseCode
        }

        check
    }

    static {
        String.metaClass.isRelativeUrl {
            return delegate.startsWith('/')
        }
        String.metaClass.isLocalhostUrl {
            return delegate.contains('localhost')
        }
        String.metaClass.isOldBlogLink {
            return delegate.contains('joelforjava.co/')
        }
    }
}
