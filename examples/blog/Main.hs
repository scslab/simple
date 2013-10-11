{-# LANGUAGE OverloadedStrings #-}

module Main where

import qualified Data.ByteString.Char8 as S8 (pack)
import Web.Simple
import Web.Simple.Auth
import Web.Simple.Cache
import Web.REST (restIndex, rest, routeREST)
import System.Environment
import Network.Wai
import Network.Wai.Middleware.Static
import Network.Wai.Handler.Warp
import Network.Wai.Middleware.MethodOverridePost
import Network.Wai.Middleware.RequestLogger
import System.FilePath

import Common
import Blog.Controllers.CommentsController
import Blog.Controllers.PostsController

app runner = do
  env <- getEnvironment
  let adminUser = maybe "admin" S8.pack $ lookup "ADMIN_USERNAME" env
  let adminPassword = maybe "password" S8.pack $ lookup "ADMIN_PASSWORD" env

  let requireAuth = basicAuth "Simple Blog Admin" adminUser adminPassword
  
  settings <- newAppSettings

  runner $ methodOverridePost $
    controllerApp settings $ do
      routePattern "admin" $ requireAuth $ do
        routeName "posts" $ do
          routePattern ":post_id/comments" $ commentsAdminController
          routeREST $ postsAdminController
        routeTop $ respond $ redirectTo "/admin/posts/"
      routeName "posts" $ do
        routePattern ":post_id/comments" $ commentsController
        routeREST $ postsController
      routeTop $ restIndex $ postsController
      fromApp $ staticPolicy (addBase "static") $ const $ return notFound

main :: IO ()
main = do
  env <- getEnvironment
  let port = maybe 3000 read $ lookup "PORT" env
  putStrLn $ "Starting server on port " ++ (show port)
  let logger = case lookup "ENV" env of
                 Just "development" -> logStdoutDev
                 _ -> logStdout
  app (run port . logger)

