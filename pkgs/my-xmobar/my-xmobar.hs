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

config :: Config
config =
  defaultConfig
    { font = "xft:Rounded Mgen+ 1mn:size=12"
    , bgColor = "#1a1e1b"
    , fgColor = "#676767"
    , lowerOnStart = True
    , position = undefined -- overwritten later
    , commands =
        [ Run $
            Network
              "wlp2s0"
              [ "-t"
              , " ↓<rx> : ↑<tx> (Kb/s)"
              , "-L"
              , "40"
              , "-H"
              , "200"
              , "--normal"
              , "#d3d7cf"
              , "--high"
              , "#88b986"
              --, "-S"       , "True"
              ]
              10
        , Run $
            Cpu
              [ "-t"
              , "Cpu: <total>%"
              , "-L"
              , "3"
              , "-H"
              , "50"
              , "--normal"
              , "green"
              , "--high"
              , "red"
              ]
              10
        , Run $
            Memory
              [ "-t"
              , "Mem: <usedratio>%"
              , "-L"
              , "40"
              , "-H"
              , "90"
              , "--normal"
              , "#d3d7cf"
              , "--high"
              , "#c16666"
              ]
              10
        , Run $
            BatteryP
              ["BAT0"]
              [ "-t"
              , "Bat: <acstatus>"
              , "-L"
              , "20"
              , "-H"
              , "80"
              , "--low"
              , "#c16666"
              , "--normal"
              , "#d3d7cf"
              , "--"
              , "-o"
              , "<left>% (<timeleft>)"
              , "-O"
              , "Charging <left>%"
              , "-i"
              , "<left>%"
              ]
              50
        , Run $ Volume "default" "Master" [] 10
        , Run $ Date "<fc=#c7a273>%a %m/%d %H:%M</fc>" "date" 10
        , Run StdinReader
        ]
    , sepChar = "%"
    , alignSep = "}{"
    , template =
        " %StdinReader% }{ %wlp2s0% | %cpu% | %memory% | %default:Master% | %battery% | %date% "
    }

run :: X.Display -> IO ()
run display = do
  log' . show =<< getFileSystemEncoding
  log' . show =<< getLocaleEncoding
  log' . show =<< getForeignEncoding
  rs <- X.getScreenInfo display
  x <- getEnvironment
  forM_ x $ \(k, v) -> do
    appendFile "/tmp/fuga" $ show k <> " = " <> show v <> "\n"
  let xpos = 0
      ypos = 0
      width = fromIntegral $ foldl max 0 $ map rect_width rs
      height = case width of
        3840 -> 40
        2560 -> 30
        1920 -> 20
        _ -> undefined
      config' = config {position = Static {xpos, ypos, width, height}}
  tryAnyDeep (xmobar config') >>= \case
    Right () -> pure ()
    Left e -> do
      print e
      log' (show e)

log' :: String -> IO ()
log' = appendFile "/tmp/xmobar.error"

main :: IO ()
main = Main.run =<< X.openDisplay ""
