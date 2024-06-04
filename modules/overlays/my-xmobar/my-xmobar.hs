{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE NamedFieldPuns #-}

import Data.List (intercalate)
import GHC.IO.Encoding
import Graphics.X11.Xinerama as X
import Graphics.X11.Xlib.Display as X
import Graphics.X11.Xlib.Types as X
import RIO
import RIO.Partial (fromJust)
import System.Environment (
  getEnvironment,
  setEnv,
 )
import Xmobar

mkConfig :: XPosition -> String -> Config
mkConfig position font =
  defaultConfig
    { font = font
    , bgColor = "#1a1e1b"
    , fgColor = "#676767"
    , lowerOnStart = True
    , position
    , commands =
        [ Run $
            DynNetwork
              [ "--template"  , "↓<rx> : ↑<tx> (Kb/s)"
              , "--Low"       , "0"
              , "--High"      , "1000"
              , "--low"       , "#d3d7cf"
              , "--normal"    , "#d3d7cf"
              , "--high"      , "#88b986"
              ] 10
        , Run $
            Cpu
              [ "-t"          , "Cpu: <total>%"
              , "-L"          , "3"
              , "-H"          , "50"
              , "--normal"    , "green"
              , "--high"      , "red"
              ]
              10
        , Run $
            Memory
              [ "-t"          , "Mem: <usedratio>%"
              , "-L"          , "40"
              , "-H"          , "90"
              , "--normal"    , "#d3d7cf"
              , "--high"      , "#c16666"
              ]
              10
        , Run $
            BatteryP
              ["BAT0"]
              [ "-t"          , "Bat: <acstatus>"
              , "-L"          , "20"
              , "-H"          , "80"
              , "--low"       , "#c16666"
              , "--normal"    , "#d3d7cf"
              , "--"
              , "-o"          , "<left>% (<timeleft>)"
              , "-O"          , "Charging <left>%"
              , "-i"          , "<left>%"
              ]
              50
        , Run $ Volume "default" "Master" [] 10
        , Run $ Com "my-xmobar-volume" [] "volume" 10
        , Run $ Date "<fc=#c7a273>%a %m/%d %H:%M</fc>" "date" 10
        , Run StdinReader
        ]
    , sepChar = "%"
    , alignSep = "}{"
    , template =
        " %StdinReader% }{ %dynnetwork% | %cpu% | %memory% | %volume% | %date% "
    }

run :: X.Display -> IO ()
run display = do
  rs <- X.getScreenInfo display
  let xpos = 0
      ypos = 0
      width = fromIntegral $ foldl max 0 $ map rect_width rs
      height = case width of
        3840 -> 40
        2560 -> 30
        1920 -> 20
        _ -> 20
      font = case width of
        3840 -> "xft:Rounded Mgen+ 1mn:size=18"
        _ -> "xft:Rounded Mgen+ 1mn:size=12"
      config = mkConfig Static {xpos, ypos, width, height} font
  tryAnyDeep (xmobar config) >>= \case
    Right () -> pure ()
    Left e -> do
      print e
      appendFile "/tmp/xmobar.error" (show e)

main :: IO ()
main = Main.run =<< X.openDisplay ""
