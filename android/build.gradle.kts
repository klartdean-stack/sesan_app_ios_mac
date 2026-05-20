buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.0.0")
        // 🎯 កែជួរខាងក្រោមនេះ ពី 1.8.10 មកជា 1.9.20
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.20") 
        classpath("com.google.gms:google-services:4.3.15") // បើអាច Update ទៅ .15 តែម្តង
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = file("../build")
subprojects {
    project.buildDir = file("${rootProject.buildDir}/${project.name}")
}
subprojects {
    // កែជួរនេះ៖ ប្រើ try-catch ឬ check ប្រសិនបើមាន project :app ទើបឱ្យវាធ្វើការ
    if (project.name != "app") {
        evaluationDependsOn(":app")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}