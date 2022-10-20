# TODO Board

Experimenting with a tech stack of Spring Boot and Elm to create a desktop application.

## Build instructions

1. Build the front end with `npm run build` in the src/main/elm directory.
2. Create a distribution copy of it with  `npm run dist`
3. Go to top level directory and build the application with `mvn install`. The application is `target/board-1.0.0.SNAPSHOT.jar` folder.