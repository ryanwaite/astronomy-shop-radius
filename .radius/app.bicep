extension radius

param environment string

@secure()
param flagdConfig string

@secure()
param postgresConnectionString string

@secure()
param postgresPassword string

@secure()
param registryPassword string

@secure()
param registryUsername string

var source = 'git::https://github.com/ryanwaite/astronomy-shop-radius.git?ref=12dbef5dfde1df1b902ca74b7d2b03ada89eceef'

resource astronomyShopRadiusApp 'Radius.Core/applications@2025-08-01-preview' = {
  name: 'astronomy-shop-radius'
  properties: {
    environment: environment
  }
}

// Do not change this Secret's name value from 'radius-ghcr-registry-creds'.
// The containerImages recipe looks up registry credentials by that fixed name.
resource registryCreds 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'radius-ghcr-registry-creds'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: '.radius/app.bicep'
    data: {
      password: {
        value: registryPassword
      }
      username: {
        value: registryUsername
      }
    }
  }
}

resource flagdConfigSecret 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'flagd-config'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/flagd/demo.flagd.json'
    data: {
      'demo.flagd.json': {
        value: flagdConfig
      }
    }
  }
}

resource postgresSecret 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'postgres-secret'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/postgresql/init.sql'
    data: {
      connectionString: {
        value: postgresConnectionString
      }
      password: {
        value: postgresPassword
      }
    }
  }
}

resource adImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'ad-image'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/ad/Dockerfile'
    tag: '12dbef5'
    build: {
      source: source
      dockerfile: 'src/ad/Dockerfile'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource cartImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'cart-image'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/cart/src/Dockerfile'
    tag: '12dbef5'
    build: {
      source: source
      dockerfile: 'src/cart/src/Dockerfile'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource checkoutImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'checkout-image'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/checkout/Dockerfile'
    tag: '12dbef5'
    build: {
      source: source
      dockerfile: 'src/checkout/Dockerfile'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource currencyImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'currency-image'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/currency/Dockerfile'
    tag: '12dbef5'
    build: {
      source: source
      dockerfile: 'src/currency/Dockerfile'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource emailImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'email-image'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/email/Dockerfile'
    tag: '12dbef5'
    build: {
      source: source
      dockerfile: 'src/email/Dockerfile'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource flagdUiImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'flagd-ui-image'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/flagd-ui/Dockerfile'
    tag: '12dbef5'
    build: {
      source: source
      dockerfile: 'src/flagd-ui/Dockerfile'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource frontendImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'frontend-image'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/frontend/Dockerfile'
    tag: '12dbef5'
    build: {
      source: source
      dockerfile: 'src/frontend/Dockerfile'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource frontendProxyImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'frontend-proxy-image'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/frontend-proxy/Dockerfile'
    tag: '12dbef5'
    build: {
      source: source
      dockerfile: 'src/frontend-proxy/Dockerfile'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource imageProviderImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'image-provider-image'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/image-provider/Dockerfile'
    tag: '12dbef5'
    build: {
      source: source
      dockerfile: 'src/image-provider/Dockerfile'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource loadGeneratorImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'load-generator-image'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/load-generator/Dockerfile'
    tag: '12dbef5'
    build: {
      source: source
      dockerfile: 'src/load-generator/Dockerfile'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource paymentImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'payment-image'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/payment/Dockerfile'
    tag: '12dbef5'
    build: {
      source: source
      dockerfile: 'src/payment/Dockerfile'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource productCatalogImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'product-catalog-image'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/product-catalog/Dockerfile'
    tag: '12dbef5'
    build: {
      source: source
      dockerfile: 'src/product-catalog/Dockerfile'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource quoteImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'quote-image'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/quote/Dockerfile'
    tag: '12dbef5'
    build: {
      source: source
      dockerfile: 'src/quote/Dockerfile'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource recommendationImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'recommendation-image'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/recommendation/Dockerfile'
    tag: '12dbef5'
    build: {
      source: source
      dockerfile: 'src/recommendation/Dockerfile'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource shippingImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'shipping-image'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/shipping/Dockerfile'
    tag: '12dbef5'
    build: {
      source: source
      dockerfile: 'src/shipping/Dockerfile'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource telemetryDocsImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'telemetry-docs-image'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/telemetry-docs/Dockerfile'
    tag: '12dbef5'
    build: {
      source: source
      dockerfile: 'src/telemetry-docs/Dockerfile'
      platforms: [
        'linux/amd64'
      ]
    }
  }
  dependsOn: [
    registryCreds
  ]
}

resource flagdContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'flagd'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/flagd/demo.flagd.json'
    containers: {
      flagd: {
        image: 'ghcr.io/open-feature/flagd:v0.16.0'
        args: [
          'start'
          '--uri'
          'file:./etc/flagd/demo.flagd.json'
        ]
        ports: {
          grpc: {
            containerPort: 8013
          }
          ofrep: {
            containerPort: 8016
          }
        }
        volumeMounts: [
          {
            volumeName: 'config'
            mountPath: '/etc/flagd'
          }
        ]
      }
    }
    volumes: {
      config: {
        secretName: flagdConfigSecret.name
      }
    }
  }
}

resource postgresContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'astronomy-db'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/postgresql/init.sql'
    containers: {
      postgres: {
        image: 'postgres:18.4'
        args: [
          '-c'
          'shared_preload_libraries=pg_stat_statements'
        ]
        env: {
          POSTGRES_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                secretName: postgresSecret.name
                key: 'password'
              }
            }
          }
        }
        ports: {
          postgres: {
            containerPort: 5432
          }
        }
      }
    }
  }
}

resource valkeyContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'valkey-cart'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/cart/src/Program.cs#L33'
    containers: {
      valkey: {
        image: 'ghcr.io/valkey-io/valkey:9.0.4-alpine3.23'
        ports: {
          redis: {
            containerPort: 6379
          }
        }
      }
    }
  }
}

resource adContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'ad'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/ad/src/main/java/oteldemo/AdService.java#L356'
    containers: {
      ad: {
        image: adImage.properties.imageReference
        env: {
          AD_PORT: {
            value: '9555'
          }
          AD_PROMETHEUS_PORT: {
            value: '9465'
          }
          FLAGD_HOST: {
            value: flagdContainer.properties.hosts.flagd
          }
          FLAGD_PORT: {
            value: '8013'
          }
        }
        ports: {
          grpc: {
            containerPort: 9555
          }
          metrics: {
            containerPort: 9465
          }
        }
      }
    }
  }
}

resource cartContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'cart'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/cart/src/Program.cs#L1'
    containers: {
      cart: {
        image: cartImage.properties.imageReference
        env: {
          ASPNETCORE_URLS: {
            value: 'http://*:7070'
          }
          CART_PORT: {
            value: '7070'
          }
          FLAGD_HOST: {
            value: flagdContainer.properties.hosts.flagd
          }
          FLAGD_PORT: {
            value: '8013'
          }
          VALKEY_ADDR: {
            value: '${valkeyContainer.properties.hosts.valkey}:6379'
          }
        }
        ports: {
          grpc: {
            containerPort: 7070
          }
        }
      }
    }
  }
}

resource currencyContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'currency'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/currency/src/server.cpp#L331'
    containers: {
      currency: {
        image: currencyImage.properties.imageReference
        env: {
          CURRENCY_PORT: {
            value: '7001'
          }
          IPV6_ENABLED: {
            value: 'false'
          }
        }
        ports: {
          grpc: {
            containerPort: 7001
          }
        }
      }
    }
  }
}

resource emailContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'email'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/email/email_server.rb'
    containers: {
      email: {
        image: emailImage.properties.imageReference
        env: {
          APP_ENV: {
            value: 'production'
          }
          EMAIL_PORT: {
            value: '6060'
          }
          FLAGD_HOST: {
            value: flagdContainer.properties.hosts.flagd
          }
          FLAGD_PORT: {
            value: '8013'
          }
        }
        ports: {
          http: {
            containerPort: 6060
          }
        }
      }
    }
  }
}

resource paymentContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'payment'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/payment/index.js'
    containers: {
      payment: {
        image: paymentImage.properties.imageReference
        env: {
          FLAGD_HOST: {
            value: flagdContainer.properties.hosts.flagd
          }
          FLAGD_PORT: {
            value: '8013'
          }
          IPV6_ENABLED: {
            value: 'false'
          }
          PAYMENT_PORT: {
            value: '50051'
          }
        }
        ports: {
          grpc: {
            containerPort: 50051
          }
        }
      }
    }
  }
}

resource productCatalogContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'product-catalog'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/product-catalog/main.go#L103'
    containers: {
      productCatalog: {
        image: productCatalogImage.properties.imageReference
        env: {
          DB_CONNECTION_STRING: {
            valueFrom: {
              secretKeyRef: {
                secretName: postgresSecret.name
                key: 'connectionString'
              }
            }
          }
          FLAGD_HOST: {
            value: flagdContainer.properties.hosts.flagd
          }
          FLAGD_PORT: {
            value: '8013'
          }
          PRODUCT_CATALOG_PORT: {
            value: '3550'
          }
        }
        ports: {
          grpc: {
            containerPort: 3550
          }
        }
      }
    }
  }
}

resource quoteContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'quote'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/quote/public/index.php'
    containers: {
      quote: {
        image: quoteImage.properties.imageReference
        env: {
          IPV6_ENABLED: {
            value: 'false'
          }
          QUOTE_PORT: {
            value: '8090'
          }
        }
        ports: {
          http: {
            containerPort: 8090
          }
        }
      }
    }
  }
}

resource recommendationContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'recommendation'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/recommendation/recommendation_server.py#L129'
    containers: {
      recommendation: {
        image: recommendationImage.properties.imageReference
        env: {
          FLAGD_HOST: {
            value: flagdContainer.properties.hosts.flagd
          }
          FLAGD_PORT: {
            value: '8013'
          }
          PRODUCT_CATALOG_ADDR: {
            value: '${productCatalogContainer.properties.hosts.productCatalog}:3550'
          }
          RECOMMENDATION_PORT: {
            value: '9001'
          }
        }
        ports: {
          grpc: {
            containerPort: 9001
          }
        }
      }
    }
  }
}

resource shippingContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'shipping'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/shipping/src/main.rs#L18'
    containers: {
      shipping: {
        image: shippingImage.properties.imageReference
        env: {
          FLAGD_HOST: {
            value: flagdContainer.properties.hosts.flagd
          }
          FLAGD_PORT: {
            value: '8013'
          }
          IPV6_ENABLED: {
            value: 'false'
          }
          QUOTE_ADDR: {
            value: 'http://${quoteContainer.properties.hosts.quote}:8090'
          }
          SHIPPING_PORT: {
            value: '50050'
          }
        }
        ports: {
          http: {
            containerPort: 50050
          }
        }
      }
    }
  }
}

resource checkoutContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'checkout'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/checkout/main.go#L163'
    containers: {
      checkout: {
        image: checkoutImage.properties.imageReference
        env: {
          CART_ADDR: {
            value: '${cartContainer.properties.hosts.cart}:7070'
          }
          CHECKOUT_PORT: {
            value: '5050'
          }
          CURRENCY_ADDR: {
            value: '${currencyContainer.properties.hosts.currency}:7001'
          }
          EMAIL_ADDR: {
            value: 'http://${emailContainer.properties.hosts.email}:6060'
          }
          FLAGD_HOST: {
            value: flagdContainer.properties.hosts.flagd
          }
          FLAGD_PORT: {
            value: '8013'
          }
          PAYMENT_ADDR: {
            value: '${paymentContainer.properties.hosts.payment}:50051'
          }
          PRODUCT_CATALOG_ADDR: {
            value: '${productCatalogContainer.properties.hosts.productCatalog}:3550'
          }
          SHIPPING_ADDR: {
            value: 'http://${shippingContainer.properties.hosts.shipping}:50050'
          }
        }
        ports: {
          grpc: {
            containerPort: 5050
          }
        }
      }
    }
  }
}

resource frontendContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'frontend'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/frontend/pages/index.tsx'
    containers: {
      frontend: {
        image: frontendImage.properties.imageReference
        env: {
          AD_ADDR: {
            value: '${adContainer.properties.hosts.ad}:9555'
          }
          CART_ADDR: {
            value: '${cartContainer.properties.hosts.cart}:7070'
          }
          CHECKOUT_ADDR: {
            value: '${checkoutContainer.properties.hosts.checkout}:5050'
          }
          CURRENCY_ADDR: {
            value: '${currencyContainer.properties.hosts.currency}:7001'
          }
          ENV_PLATFORM: {
            value: 'local'
          }
          FLAGD_HOST: {
            value: flagdContainer.properties.hosts.flagd
          }
          FLAGD_PORT: {
            value: '8013'
          }
          PORT: {
            value: '8080'
          }
          PRODUCT_CATALOG_ADDR: {
            value: '${productCatalogContainer.properties.hosts.productCatalog}:3550'
          }
          RECOMMENDATION_ADDR: {
            value: '${recommendationContainer.properties.hosts.recommendation}:9001'
          }
          SHIPPING_ADDR: {
            value: 'http://${shippingContainer.properties.hosts.shipping}:50050'
          }
        }
        ports: {
          web: {
            containerPort: 8080
          }
        }
      }
    }
  }
}

resource flagdUiContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'flagd-ui'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/flagd-ui/lib/flagd_ui/application.ex#L12'
    containers: {
      flagdUi: {
        image: flagdUiImage.properties.imageReference
        env: {
          FLAGD_UI_PORT: {
            value: '4000'
          }
          PHX_HOST: {
            value: 'localhost'
          }
        }
        ports: {
          web: {
            containerPort: 4000
          }
        }
      }
    }
  }
}

resource imageProviderContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'image-provider'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/image-provider/nginx.conf.template'
    containers: {
      imageProvider: {
        image: imageProviderImage.properties.imageReference
        env: {
          IMAGE_PROVIDER_PORT: {
            value: '8081'
          }
        }
        ports: {
          web: {
            containerPort: 8081
          }
        }
      }
    }
  }
}

resource telemetryDocsContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'telemetry-docs'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/telemetry-docs/nginx.conf.template'
    containers: {
      telemetryDocs: {
        image: telemetryDocsImage.properties.imageReference
        env: {
          TELEMETRY_DOCS_PORT: {
            value: '8000'
          }
        }
        ports: {
          web: {
            containerPort: 8000
          }
        }
      }
    }
  }
}

resource loadGeneratorContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'load-generator'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/load-generator/locustfile.py#L136'
    containers: {
      loadGenerator: {
        image: loadGeneratorImage.properties.imageReference
        env: {
          FLAGD_HOST: {
            value: flagdContainer.properties.hosts.flagd
          }
          FLAGD_OFREP_PORT: {
            value: '8016'
          }
          FLAGD_PORT: {
            value: '8013'
          }
          LOCUST_AUTOSTART: {
            value: 'true'
          }
          LOCUST_HEADLESS: {
            value: 'false'
          }
          LOCUST_HOST: {
            value: 'http://frontend-proxy-frontendProxy:8080'
          }
          LOCUST_USERS: {
            value: '5'
          }
          LOCUST_WEB_HOST: {
            value: '0.0.0.0'
          }
          LOCUST_WEB_PORT: {
            value: '8089'
          }
        }
        ports: {
          web: {
            containerPort: 8089
          }
        }
      }
    }
  }
}

resource frontendProxyContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'frontend-proxy'
  properties: {
    environment: environment
    application: astronomyShopRadiusApp.id
    codeReference: 'src/frontend-proxy/envoy.tmpl.yaml'
    containers: {
      frontendProxy: {
        image: frontendProxyImage.properties.imageReference
        env: {
          ENVOY_ADDR: {
            value: '0.0.0.0'
          }
          ENVOY_ADMIN_PORT: {
            value: '10000'
          }
          ENVOY_PORT: {
            value: '8080'
          }
          FLAGD_HOST: {
            value: flagdContainer.properties.hosts.flagd
          }
          FLAGD_PORT: {
            value: '8013'
          }
          FLAGD_UI_HOST: {
            value: flagdUiContainer.properties.hosts.flagdUi
          }
          FLAGD_UI_PORT: {
            value: '4000'
          }
          FRONTEND_HOST: {
            value: frontendContainer.properties.hosts.frontend
          }
          FRONTEND_PORT: {
            value: '8080'
          }
          IMAGE_PROVIDER_HOST: {
            value: imageProviderContainer.properties.hosts.imageProvider
          }
          IMAGE_PROVIDER_PORT: {
            value: '8081'
          }
          LOCUST_WEB_HOST: {
            value: loadGeneratorContainer.properties.hosts.loadGenerator
          }
          LOCUST_WEB_PORT: {
            value: '8089'
          }
          TELEMETRY_DOCS_HOST: {
            value: telemetryDocsContainer.properties.hosts.telemetryDocs
          }
          TELEMETRY_DOCS_PORT: {
            value: '8000'
          }
        }
        ports: {
          admin: {
            containerPort: 10000
          }
          web: {
            containerPort: 8080
          }
        }
      }
    }
  }
}
