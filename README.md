# Build Buildpack applications in Wercker

This step will mimic the Heroku/Cloud Foundry buildpack compilation process.

To mostly replicate the Heroku build process, use `heroku/cedar:14` as base box for your build.

## Options

* `platform`: (optional, default: `heroku`) The target build platform. Supported values: `heroku`, `cloudfoundry`
* `stack`: (optional, default: `cedar-14` for Heroku, `cflinuxfs2` for Cloud Foundry) The build stack
* `buildpacks`: (optional) If you use custom buildpacks but have not listed them in `app.json`, you can list the URLs of required buildpacks here, separated by spaces.

## Example

    build:
      steps:
        - inz/buildpack-build

## License

The MIT License

## Changelog

### 0.0.1

* Initial Release