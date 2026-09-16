def runTest() {
    println '============================================================'
    println 'External Groovy test'
    println '============================================================'
    println "Java version: ${System.getProperty('java.version')}"
    println "Operating system: ${System.getProperty('os.name')}"
    println "Working directory: ${new File('.').canonicalPath}"

    File hemsDirectory = new File('HEMS')

    if (!hemsDirectory.isDirectory()) {
        throw new IllegalStateException(
            "HEMS directory was not found: ${hemsDirectory.canonicalPath}"
        )
    }

    println "HEMS directory found: ${hemsDirectory.canonicalPath}"
    println 'External Groovy test completed successfully.'
}

return this
