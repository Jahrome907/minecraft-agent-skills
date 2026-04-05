plugins {
    java
}

repositories {
    mavenCentral()
    maven("https://repo.papermc.io/repository/maven-public/")
    maven("https://repo.mockbukkit.org/artifactory/mockbukkit/")
}

dependencies {
    testImplementation("org.junit.jupiter:junit-jupiter:5.11.0")
    testImplementation("com.github.seeseemelk:MockBukkit-v1.21:3.127.0")
}

tasks.test {
    useJUnitPlatform()
}