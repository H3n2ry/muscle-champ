import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Credenciais do keystore de release. O arquivo `android/key.properties` e o
// proprio .jks ficam FORA do controle de versao (ver .gitignore) — quem tem o
// keystore assina o app, entao vaza-lo permite publicar atualizacao falsa em
// nome do Muscle Champ.
//
// Sem o arquivo, o build de release cai na chave de debug e continua
// funcionando para desenvolvimento. Isso e proposital: quem clona o
// repositorio consegue compilar sem precisar da chave. O que NAO pode e
// publicar assim — o Play recusa APK assinado com a chave de debug.
//
// ⚠️ Perder o keystore significa perder a capacidade de atualizar o app na
// Play Store para sempre. Guardar copia em lugar seguro e fora desta maquina.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "br.com.musclechamp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Dominio proprio invertido. Trocado de `com.example.muscle_camp` em
        // 01/09/2026 — o Play rejeita `com.example.*`, e depois de publicado
        // mudar o applicationId cria um app NOVO: quem instalou nao recebe
        // atualizacao. Esta foi a ultima janela barata para mexer nisso.
        //
        // Amarra o Google Sign-In junto com o SHA-1 da chave de assinatura:
        // trocar qualquer um dos dois exige refazer a configuracao no Google
        // Cloud Console.
        applicationId = "br.com.musclechamp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Com key.properties presente, assina de verdade. Sem ele, cai na
            // chave de debug — o build continua rodando, mas o Play recusa.
            //
            // O SHA-1 desta chave amarra o Google Sign-In no Android. Depois de
            // gerar o keystore, pegar com:
            //   keytool -list -v -keystore <caminho.jks> -alias <alias>
            // e cadastrar no Google Cloud Console junto com o applicationId.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
