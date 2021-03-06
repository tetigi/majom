-- | Common functions and types for majom.
module Majom.Common where

import qualified Data.Vector as V
import Control.Concurrent

instance (Num a, Num b) => Num (a,b) where
  (x1,x2) + (y1,y2) = (x1+y1,x2+y2)
  (x1,x2) * (y1,y2) = (x1*y1,x2*y2)
  negate (x,y) = (negate x, negate y)
  abs (x,y) = (abs x, abs y)
  signum (x,y) = (signum x, signum y)
  fromInteger i = (fromInteger i, fromInteger i)

instance (Num a) => Num (V.Vector a) where
  as + bs = V.zipWith (+) as bs
  as - bs = V.zipWith (-) as bs
  as * bs = V.zipWith (*) as bs
  negate a = V.map negate a
  fromInteger x = error "Cannot instantiate Vector from Integer :("
  abs m = V.map abs m
  signum _ = 1

-- | Vector scaling function.
(|*|) :: Vector -> Double -> Vector
(|*|) v d = V.map (*d) v

-- | Inverse Vector scaling function.
(|/|) :: Vector -> Double -> Vector
(|/|) v d = V.map (/d) v

-- | Unit a vector
vectorUnit :: Vector -> Vector
vectorUnit v
  | size > 0  = v |/| size
  | otherwise = error "Tried taking unit vector of a size-zero vector!"
  where
    size = vectorSize v

-- | Size a vector
vectorSize :: Vector -> Double
vectorSize v = sqrt $ V.sum $ v * v

-- | Vector constructor
vector2 :: Double -> Double -> Vector
vector2 x y = V.fromList [x, y]

-- | Creates a vector from a list.
vector :: [Double] -> Vector
vector = V.fromList

-- | Gets the X value of a vector.
vectorX :: Vector -> Double
vectorX = (V.! 0)

-- | Gets the Y value of a vector.
vectorY :: Vector -> Double
vectorY = (V.! 1)

-- | Gets the Z value of a vector.
vectorZ :: Vector -> Double
vectorZ = (V.! 2)

-- | Gets the dot product of two vectors
vecDot :: Vector -> Vector -> Double
vecDot v1 v2 =
  V.sum (v1 * v2)

-- | Print a vector in a Python readable form
prettyVec :: Vector -> String
prettyVec v = 
  if V.length v /= 3
    then error "Vector is too short to pretty print..."
    else foldl1 ((++) . (++ ",")) $ map (show . (sigFigs 5)) 
      [v V.! 0, v V.! 1, v V.! 2]

-- | Print a position in a nice way
prettyPos :: Position -> String
prettyPos p = (prettyVec $ getVec p) ++ "," ++ (show $ getFacing p) 

-- | Simple Vector, made from doubles.
type Vector = V.Vector Double

-- | Position for objects.
data Position = Position { getVec :: Vector, getFacing :: Double }
  deriving (Eq, Show)

-- | Convert degrees to radians
radians :: Double -> Double
radians x = x*pi/180

-- | Convert radians to degrees
degrees :: Double -> Double
degrees x = x*180/pi

-- | Normalises degrees to 0 - 360
degNorm :: Double -> Double
degNorm x = 
  head $ dropWhile (< 0) $ iterate (+360) $ head $ dropWhile (>360) $ iterate (flip (-)360) x

-- | Gets the difference (min) between two degrees.
degDiff :: Double -> Double -> Double
degDiff x y
  | abs (x-y) > 180 = (if x > y then 1 else -1) * ((360 - max x y) + min x y)
  | otherwise =  y-x

instance Num (Position) where
  as + bs = as { getVec = (getVec as) + (getVec bs)}
  as * bs = as { getVec = (getVec as) * (getVec bs)}
  negate (Position p o) = Position (negate p) (o + 180)
  fromInteger x = error "Cannot instantiate Position from Integer :("
  abs m = m { getVec = abs (getVec m) }
  signum _ = 1

-- | Position data structure
(<+>) :: Position -> Vector -> Position
(<+>) p v = p { getVec = ((getVec p) + v) }

-- | Velocity for objects.
type Velocity = Vector

-- | Acceleration for objects.
type Acceleration = Vector

-- | Force for objects.
type Force = Vector

-- | Time for simulation (in seconds)
type Time = Double

-- | Power from the controller
type Power = Int

-- | Surface data structure
data Surface = Surface { sPoint :: Vector, sNorm :: Vector, sSpecial :: Bool }
  deriving (Show, Read)

-- | Gravity force constant
gravity :: Force
gravity = vector [0, (-9.8), 0]

-- | Calculates the acceleration at a given observation time, given 
-- a string of observed events.
-- There is an implicit ordering, with newest observations at the front.
calcObservedAccel :: [(Power, Position, Time)] -> [(Power, Acceleration)]
calcObservedAccel obs = if length obs < 3 then [] else
  calc x
  where
    x = reverse obs

    calc :: [(Power, Position, Time)] -> [(Power, Acceleration)]
    calc v@((_, pos'', t''):(_, pos', t'):(pwr, pos, t):vs) =
      (pwr, accel) : calc (tail v)
      where
        vel' = (getVec (pos' - pos'')) |/| (t'' - t')
        vel  = (getVec (pos - pos')) |/| (t' - t)
        accel = (vel - vel') |/| (t' - t)
    calc vs = []

-- | Tolerance for use with approximations.
tolerance :: Double
tolerance = 1e-5

-- | Approximately equals.
(~=) :: Double -> Double -> Bool
(~=) a b = abs (a - b) < tolerance

-- | Rounds a number to a certain number of significant figures.
sigFigs :: (RealFrac a) => Int -> a -> a
sigFigs d n = (fromIntegral (round (n * p))) / p
  where 
    p = 10 ^ (d-1)

-- | Sleeps for x milliseconds.
milliSleep :: Int -> IO ()
milliSleep = threadDelay . (*) 1000
