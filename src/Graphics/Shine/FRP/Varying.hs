module Graphics.Shine.FRP.Varying (
  ShineInput(..),
  playVarying,
  playVaryingIO,
  timeNumeric,
  timeEvent,
  isDownButton,
  isDownKey,
  mouseMove
) where

import Graphics.Shine.Input
import Graphics.Shine.Picture
import Graphics.Shine
import Control.Varying.Core
import Control.Varying.Event
import Web.KeyCode
import Data.Functor.Identity


data ShineInput = Input Input | Time Float


playVarying :: Float -> (Int, Int) -> Var ShineInput Picture -> IO ()
playVarying fps dims v =
    play fps dims (Empty, v) fst (\a b -> runIdentity $ handleInput a b) (\a b -> runIdentity $ step a b)

playVaryingIO :: Float -> (Int, Int) -> VarT IO ShineInput Picture -> IO ()
playVaryingIO fps dims v =
    playIO fps dims (Empty, v) (const $ return . fst) (const handleInput) (const step)

handleInput :: Monad m => Input -> (Picture, VarT m ShineInput Picture) -> m (Picture, VarT m ShineInput Picture)
handleInput i (_,v) = do
  v' <- execVar v $ Input i
  return (Empty, v')

step :: Monad m => Float -> (Picture, VarT m ShineInput Picture) -> m (Picture, VarT m ShineInput Picture)
step t (_,v) = runVarT v $ Time t

-- ## Useful Vars

--MAYBE wrap in Event

timeNumeric :: Monad m => VarT m ShineInput Float
timeNumeric = var f
  where
    f (Input _) = 0
    f (Time t) = t

timeEvent :: Monad m => VarT m ShineInput (Event Float)
timeEvent = var f
  where
    f (Input _) = NoEvent
    f (Time t) = Event t


isDownButton :: Monad m => MouseBtn -> VarT m ShineInput Bool
isDownButton b = accumulate f False
  where
    f _ (Input (MouseBtn b' Down _)) | b == b' = True
    f _ (Input (MouseBtn b' Up _)) | b == b' = False
    f s _ = s

--mouseButtonsDown :: Var IO ShineInput [MouseButton]

mouseMove :: Monad m => VarT m ShineInput (Int,Int)
mouseMove = accumulate f (0,0)
  where
    f _ (Input (MouseMove coords)) = coords
    f s _ = s


isDownKey :: Monad m => Key -> VarT m ShineInput Bool
isDownKey k = accumulate f False
  where
    f _ (Input (Keyboard k' Down _)) | k == k' = True
    f _ (Input (Keyboard k' Up _)) | k == k' = False
    f s _ = s

--keysDown :: Var IO ShineInput [Key]
