jupyter_datascience_spark
================================

image for datascience & datavisualization with jupyterlab, pyspark, e.t.c.

## Using Packages (abstract)

- all images are based on `Ubuntu`
- `Python3.7.*`
- [Apache Spark](https://spark.apache.org/)
    - [using mirror](http://apache.mirror.iphh.net/spark/)
    - `3.0.0` with `hadoop2.7`
    - `2.4.6` with `hadoop2.7`
- Java8(openjdk)
    - [adoptopenjdk](https://hub.docker.com/_/adoptopenjdk?tab=tags&page=1&name=bionic)
        - `adoptopenjdk(hotspot)` (main)
        - `adoptopenjdk(openj9)`
    - [azul/zulu-openjdk](https://hub.docker.com/r/azul/zulu-openjdk)
- conda packages(yaml)
    - [for development](./conda_packages.yml)
    - [freeze env](./conda_packages_freeze.yml)
