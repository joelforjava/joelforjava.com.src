package com.joelforjava.gradle.task

import org.gradle.api.DefaultTask
import org.gradle.api.file.FileTree
import org.gradle.api.tasks.TaskAction

class CheckDraftsTask extends DefaultTask {

    String contentDirectory

    @TaskAction
    def check() {
        List drafts = collectDrafts()
        println "\n\nTotal documents in draft: ${drafts.size()}"
        (0..30).each { print '-' }
        println ''
        drafts.each {
            println " * $it"
        }
    }

    private collectDrafts() {
        FileTree tree = project.fileTree(dir: contentDirectory)

        List drafts = []
        tree.each { element ->
            if (element.isFile()) {
                element.eachLine('utf-8') { line ->
                    if (line.startsWith('status') || line.startsWith(':jbake-status')) {
                        if (line.endsWith('draft')) {
                            drafts << element.absolutePath
                        }
                        return
                    }
                    if (line.startsWith('~~~')) {
                        return
                    }
                }
            }
        }
        drafts
    }
}
