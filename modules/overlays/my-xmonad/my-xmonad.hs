{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ImportQualifiedPost #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeOperators #-}

module Main where

import RIO hiding (Const)
import RIO.List qualified as List

import Data.List.Split qualified as List
import System.Environment qualified as Env
import XMonad
import XMonad.Hooks.DynamicLog (
  PP (..),
  dynamicLogString,
  statusBar,
 )
import XMonad.Hooks.EwmhDesktops (ewmh)
import XMonad.Hooks.ManageDocks (
  AvoidStruts,
  ToggleStruts (..),
  manageDocks,
 )
import XMonad.Layout.BinaryColumn (
  BinaryColumn (..),
 )
import XMonad.Layout.Column (
  Column (..),
 )
import XMonad.Layout.ComboP (
  CombineTwoP,
  Property (..),
  SwapWindow (..),
  combineTwoP,
 )
import XMonad.Layout.Decoration (
  Decoration,
  DefaultShrinker,
 )
import XMonad.Layout.Gaps (Direction2D (..), Gaps, gaps)
import XMonad.Layout.LayoutModifier (ModifiedLayout)
import XMonad.Layout.Simplest (Simplest)
import XMonad.Layout.Tabbed (
  TabbedDecoration,
  Theme (..),
  shrinkText,
  tabbed,
 )
import XMonad.Layout.TwoPane (TwoPane (..))
import XMonad.StackSet qualified as W
import XMonad.Util.EZConfig (
  additionalKeys,
  additionalKeysP,
  removeKeysP,
 )
import XMonad.Util.Run (
  runProcessWithInput,
  safeSpawn,
 )

main :: IO ()
main = do
  terminal <- Env.lookupEnv "TERMINAL" <&> fromMaybe "konsole"
  browser <- Env.lookupEnv "BROWSER" <&> fromMaybe "firefox"
  Env.lookupEnv "XMONAD_LAYOUT" >>= \case
    Just "1" ->
      xmonad (myConfig terminal browser) {layoutHook = myLayoutHook1}
    Just "2" ->
      xmonad (myConfig terminal browser) {layoutHook = myLayoutHook2}
    _ ->
      xmonad (myConfig terminal browser) {layoutHook = myLayoutHook1}
  where
    myConfig terminal browser =
      def
        { modMask = mod4Mask
        , terminal = terminal
        , workspaces = myWorkspaces
        , focusedBorderColor = "#223377"
        , normalBorderColor = "#000000"
        , manageHook =
            manageDocks
              <+> manageHook def
              <+> composeAll
                [ className =? "plasmashell" --> doFloat
                -- , className =? "firefox-esr" --> doFloat
                , resource =? "Alert" --> doFloat -- firefox notification
                ]
        , startupHook = mapM_ spawn []
        , handleExtraArgs = \xs conf -> do
            mborder <- tryAnyDeep $ read <$> readFile "/tmp/xmonad_borderwidth"
            handleExtraArgs
              def
              xs
              conf
                { borderWidth = case mborder of
                    Right x -> x
                    Left _ -> 2
                }
        }
        `additionalKeysP`
        --
        [ ("M-g", spawn browser)
        , ("M-p", spawn "dmenu_run")
        , ("M-c", spawn "dmenu_run")
        , ("M-S-q", kill)
        , ("M-S-C-q", io exitSuccess)
        , ("M-x", spawn "sudo pm-suspend")
        , ("M-S-x", spawn "systemctl suspend")
        , ("M-<Space>", sendMessage NextLayout)
        , ("M-<Return>", focusNextScreen)
        , ("M-C-<Return>", shiftNextScreen)
        , ("M-s", swapScreen)
        , ("M-a", swapWindow)
        , ("M-d", swapPanes)
        , ("M-S-r", restart "xmonad" True)
        , ("M-k", focusUpOrAnotherPane)
        , ("M-j", focusDownOrAnotherPane)
        , ("M-S-k", focusUp)
        , ("M-S-j", focusDown)
        , ("M-S-h", spawn "systemctl suspend")
        , ("M-S-l", spawn "loginctl lock-session")
        , ("M-S-o", spawn "amixer sset Master mute")
        , ("M-S-t", spawn "amixer sset Master toggle")
        , ("M-S-s", spawn "sh -c 'flameshot gui; pkill .flameshot-wrap'")
        , ("M-C-s", spawn $ unwords ["scrot", "-s", screenShotName])
        , ("M-S-b", spawn "$HOME/.local/bin/bttoggle")
        , ("M-m", toggleTouchPad)
        ]
        `additionalKeysP`
        --
        [ ("<XF86AudioRaiseVolume>", spawn "amixer sset Master 2%+")
        , ("<XF86AudioLowerVolume>", spawn "amixer sset Master 2%-")
        , ("<XF86AudioMute>", spawn "amixer sset Master 0%")
        , ("M-<XF86AudioRaiseVolume>", spawn "xbacklight -inc 10")
        , ("M-<XF86AudioLowerVolume>", spawn "xbacklight -dec 10")
        ]
        `additionalKeys`
        --
        [ ((m .|. mod4Mask, k), windows $ f i)
        | (i, k) <- zip myWorkspaces [xK_1 .. xK_9]
        , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]
        ]
        `removeKeysP`
        --
        ["S-C-n"]

    screenShotName :: String
    screenShotName = "$HOME/Dropbox/ScreenShots/Screenshot%Y-%m-%d-%H-%M-%S.png"

    myWorkspaces :: [String]
    myWorkspaces = map show [1 .. 9 :: Int]

-------------------------------------------------------------------------------
-- Layout
-------------------------------------------------------------------------------

type (:$) = ModifiedLayout

type (:|) = Choose

infixr 6 :$

infixr 5 :|

type SimpleTab = Decoration TabbedDecoration DefaultShrinker :$ Simplest

type MyLayoutHook1 =
  SimpleTab
    :| CombineTwoP (TwoPane ()) SimpleTab SimpleTab
    :| ModifiedLayout Gaps (CombineTwoP (BinaryColumn ()) SimpleTab SimpleTab)
    :| Full

type MyLayoutHook2 =
  SimpleTab
    :| CombineTwoP (TwoPane ()) SimpleTab SimpleTab
    :| ModifiedLayout Gaps SimpleTab
    :| ModifiedLayout Gaps (CombineTwoP (TwoPane ()) SimpleTab SimpleTab)
    :| Full

data LayoutType
  = LayoutFull
  | LayoutTabbed
  | LayoutTwoCol
  | LayoutTwoRow
  deriving (Eq, Ord, Show)

myLayoutHook1 :: MyLayoutHook1 Window
myLayoutHook2 :: MyLayoutHook2 Window
(myLayoutHook1, myLayoutHook2) =
  ( myTabbed ||| myTwoPane ||| gaps [(D, 60)] myTwoCol ||| Full
  , myTabbed ||| myTwoPane ||| gaps [(D, 45)] myTabbed ||| gaps [(D, 45)] myTwoPane ||| Full
  )
  where
    myTabbed =
      tabbed
        shrinkText
        def
          { activeColor = "#1A1E1B"
          , activeTextColor = "#00FF00"
          , activeBorderColor = "#000000"
          , inactiveColor = "#1A1E1B"
          , inactiveTextColor = "#676767"
          , inactiveBorderColor = "#000000"
          , activeBorderWidth = 1
          , inactiveBorderWidth = 1
          , fontName = "xft:Rounded Mgen+ 1mn:size=8"
          , decoHeight = 30
          }
    myTwoPane = combineTwoP (TwoPane (1 / 50) (1 / 2)) myTabbed myTabbed (Const True)
    myTwoCol = combineTwoP (BinaryColumn 1.4 32) myTabbed myTabbed (Const True)

log' :: (MonadIO m) => String -> m ()
log' s = liftIO $ do
  home <- Env.lookupEnv "HOME" <&> fromMaybe "/tmp"
  appendFile (home <> "/xmonad.mylog") (s <> "\n")

-------------------------------------------------------------------------------
-- Command
-------------------------------------------------------------------------------

focusNextScreen :: X ()
focusNextScreen = withNextScreen W.view

shiftNextScreen :: X ()
shiftNextScreen = withNextScreen W.shift

swapScreen :: X ()
swapScreen = windows $ \stack -> case W.visible stack of
  [] -> stack
  x : rest ->
    stack
      { W.current = y {W.workspace = W.workspace x}
      , W.visible = x {W.workspace = W.workspace y} : rest
      }
    where
      y = W.current stack

swapWindow :: X ()
swapWindow = sendMessage SwapWindow

toggleTouchPad :: X ()
toggleTouchPad = setTouchPad . not =<< isTouchPadEnabled
  where
    setTouchPad :: Bool -> X ()
    setTouchPad b =
      safeSpawn
        "gsettings"
        [ "set"
        , "org.gnome.desktop.peripherals.touchpad"
        , "send-events"
        , if b then "enabled" else "disabled"
        ]
    isTouchPadEnabled :: X Bool
    isTouchPadEnabled = do
      out <-
        runProcessWithInput
          "gsettings"
          [ "get"
          , "org.gnome.desktop.peripherals.touchpad"
          , "send-events"
          ]
          ""
      case out of
        "'enabled'\n" -> pure True
        "'disabled'\n" -> pure False
        _ -> error' $ "toggleTouchPad: unknown input: " <> show out
      where
        error' s = log' s >> error s

focusUp :: X ()
focusUp =
  getCurrentLayoutType >>= \case
    LayoutTwoRow -> focusUpInPane
    _ -> windows W.focusUp

focusDown :: X ()
focusDown =
  getCurrentLayoutType >>= \case
    LayoutTwoRow -> focusDownInPane
    _ -> windows W.focusDown

focusUpOrAnotherPane :: X ()
focusUpOrAnotherPane =
  getCurrentLayoutType >>= \case
    LayoutTwoRow -> focusAnotherPane
    _ -> windows W.focusUp

focusDownOrAnotherPane :: X ()
focusDownOrAnotherPane =
  getCurrentLayoutType >>= \case
    LayoutTwoRow -> focusAnotherPane
    _ -> windows W.focusDown

-------------------------------------------------------------------------------
-- Utils
-------------------------------------------------------------------------------

getCurrentLayoutType :: X LayoutType
getCurrentLayoutType = parseLayoutType <$> getCurrentLayoutName

getCurrentLayoutName :: X String
getCurrentLayoutName = do
  x <- dynamicLogString def {ppOrder = \ ~[_, l, _] -> [l]}
  log' x
  pure x

parseLayoutType :: String -> LayoutType
parseLayoutType s
  | "combining Tabbed Simplest and Tabbed Simplest with TwoPane"
      `List.isPrefixOf` s =
      LayoutTwoRow
  | "combining Tabbed Simplest and Tabbed Simplest with BinaryColumn"
      `List.isPrefixOf` s =
      LayoutTwoCol
  | "Tabbed" `List.isPrefixOf` s = LayoutTabbed
  | otherwise = LayoutFull

withNextScreen :: (WorkspaceId -> WindowSet -> WindowSet) -> X ()
withNextScreen func =
  gets (W.visible . windowset) >>= \case
    [] -> pure ()
    next : _ -> windows $ func $ W.tag $ W.workspace next

-- XXX ad hoc
swapPanes :: X ()
swapPanes =
  getPanesInfo >>= \case
    Just (_all', focusedPane, unfocusedPane) -> do
      forM_ focusedPane $ \_ -> do
        sendMessage SwapWindow
        focusAnotherPane
      focusDown -- もともとのunfocusedPaneの先頭を指す
      forM_ unfocusedPane $ \_ -> do
        sendMessage SwapWindow
        focusAnotherPane
      focusAnotherPane
    Nothing -> pure ()

-- XXX ad hoc
focusAnotherPane :: X ()
focusAnotherPane =
  getPanesInfo >>= \case
    Just (all', _focusedPane, unfocusedPane) -> do
      let mVisibleOnUnfocusedPane =
            -- 多分あってる
            List.find (`elem` unfocusedPane) all'
      case mVisibleOnUnfocusedPane of
        Nothing -> log' "UnfocusedPane is empty"
        Just v -> focus v
    Nothing -> pure ()

focusUpInPane :: X ()
focusUpInPane =
  getPanesInfo >>= \case
    Just (_all', focusedPane, _unfocusedPane) -> do
      getFocusedWin >>= \case
        Just focused -> do
          let x = reverse focusedPane
          focus $ dropWhile (/= focused) (x ++ x) !! 1
        Nothing -> pure ()
    Nothing -> pure ()

focusDownInPane :: X ()
focusDownInPane =
  getPanesInfo >>= \case
    Just (_all', focusedPane, _unfocusedPane) -> do
      getFocusedWin >>= \case
        Just focused -> do
          let x = reverse focusedPane
          focus $ dropWhile (/= focused) (x ++ x) !! 1
        Nothing -> pure ()
    Nothing -> pure ()

-- XXX ad hoc
-- returns (All Windows, Forcused Pane, UnfocusedPane)
getPanesInfo :: X (Maybe ([Window], [Window], [Window]))
getPanesInfo =
  getFocusedWin >>= \case
    Nothing -> pure Nothing
    Just focused -> do
      layout <- gets $ windowset >>> W.current >>> W.workspace >>> W.layout
      -- C2Pがコンストラクタを公開していないため、showで無理やりreflectionする
      case List.splitOn "C2P " (show layout) of
        _ : s0 : _
          | _ <- ()
          , [(all', s1)] <- reads @[Word64] s0
          , [(left', s2)] <- reads @[Word64] s1
          , [(right', _s)] <- reads @[Word64] s2
          , let (focusedPane, unfocusedPane)
                  | focused `elem` left' = (left', right')
                  | otherwise = (right', left') ->
              pure $ Just (all', focusedPane, unfocusedPane)
        _ -> pure Nothing

getFocusedWin :: X (Maybe Window)
getFocusedWin =
  gets $ windowset >>> W.current >>> W.workspace >>> W.stack >>> fmap W.focus
