# TODO Board

Experimenting with a tech stack of Spring Boot and Elm to create a desktop application.

## Build instructions

1. Create a distribution copy of it with  `npm run dist` in the `src/main/elm` directory.
2. Go to top level directory and build the application with `mvn install`. The application
   is `target/board-1.0.0.SNAPSHOT.jar` folder.

## Hot load development

Both Java and Elm supports hot loading in various ways. Keep in mind that the frontend is built and copied into the
backend.

### Elm hot load

1. Start the backend.
2. Then do `npm start` in the `src/main/elm` directory.
3. Open the [src/main/elm/index.html](src/main/elm/index.html) file with your browser.

More info about `elm-watch` here: [https://lydell.github.io/elm-watch/](https://lydell.github.io/elm-watch/)

### Java hot load

Supported at least by IntelliJ. Run the backend in debug mode. Rebuild when you have made changes. If no interfaces are
changed, the server will hot load your changes, even if it has stopped on a breakpoint.