{-|
Module      : KMonad.Core.Parser.Token
Description : The different tokens that can be read from config files.
Copyright   : (c) David Janssen, 2019
License     : MIT
Maintainer  : janssen.dhj@gmail.com
Stability   : experimental
Portability : portable

We deal with reading configuration files by first parsing the entire file into a
collection of abstract data tokens. It is only in the second pass when we
interpret these data-tokens into an actual 'Kmonad.Core.Config.Config' object
that we check for correctness of the config.

This module contains all of the definitions of things that can be parsed
straight from text, in addition to KeyCode's.

-}
module KMonad.Core.Parser.Token
  ( Symbol
  , LayerId
  , InputDecoder(..)
  , InputToken(..)
  , OutputToken(..)
  , ButtonToken(..)
  , ButtonSymbol(..)
  , SourceToken(..)
  , AliasRef(..)
  , AliasDef(..)
  , LayerToken(..)
  , layerName, anchor, buttons
  , ConfigToken(..)
  , sources, layers, aliases, inputs, outputs
  )
where

import Control.Lens
import Data.Text

import KMonad.Core.KeyCode
import KMonad.Core.Matrix
import KMonad.Core.Time


--------------------------------------------------------------------------------

-- TODO: Move LayerId somewhere sane

-- | The type of 'Symbol' keywords used in our mini-language.
type Symbol = Text

-- | The type of 'LayerId', used to name layers.
type LayerId = Text

--------------------------------------------------------------------------------

-- | A token describing which input-decoder to use
data InputDecoder
  = L64   -- ^ The standard, Linux 64-bit representation of key events
  deriving (Eq, Show)

-- | A token describing which input IO to use
data InputToken
  = LinuxDeviceSource InputDecoder FilePath -- ^ The standard, Linux 64-bit input device
  deriving (Eq, Show)

-- | A token describing which output to use
-- TODO: Add the ability to give a custom name to your uinput keyboard
data OutputToken
  = UinputDevice -- ^ A Linux uinput device
  deriving (Eq, Show)

--------------------------------------------------------------------------------

-- | A token describing a button
data ButtonToken
  = BEmit KeyCode               -- ^ Corresponds to "KMonad.Domain.Button.Emit"
  | BModded KeyCode ButtonToken -- ^ Corresponds to "KMonad.Domain.Button.Around"
  | BLayerToggle LayerId        -- ^ Corresponds to "KMonad.Domain.Button.LayerToggle"
  | BTapHold Milliseconds ButtonToken ButtonToken
    -- ^ Corresponds to "KMonad.Domain.Button.TapHold"
  | BTapNext ButtonToken ButtonToken
    -- ^ Corresponds to "KMonad.Domain.Button.TapNext"
  | BTapMacro [ButtonToken]     -- ^ Corresponds to "KMoand.Domain.Button.Macro"
  | BMultiTap [(Microseconds, ButtonToken)]
    -- ^ Corresponds to "KMonad.Domain.Button.MultiTap"
  | BBlock                      -- ^ Corresponds to "KMonad.DOmain.Button.Block"
  deriving (Eq, Show)

-- | A token describing anything that can be interpreted as a 'ButtonToken'
data ButtonSymbol
  = BSToken ButtonToken -- ^ A literal 'ButtonToken'
  | BSAlias AliasRef    -- ^ A named alias, to be dereferenced later
  | Transparent         -- ^ Indicate that this keycode is not handled by the current layer
  deriving (Eq, Show)


--------------------------------------------------------------------------------

-- | A token representing the layout of 'KeyCode's that we are mapping all other
-- layers onto.
data SourceToken = SourceToken (Matrix KeyCode)
  deriving (Eq, Show)


--------------------------------------------------------------------------------

-- | A token representing the act of referring to a previously defined 'AliasDef'
data AliasRef = AliasRef Symbol             deriving (Eq, Show)

-- | A token representing the definition of an alias as correspondence between a
-- 'Symbol' and a 'ButtonToken'.
data AliasDef = AliasDef Symbol ButtonToken deriving (Eq, Show)


--------------------------------------------------------------------------------

-- | A token representing an entire layer of buttons
data LayerToken = LayerToken
  { _layerName :: LayerId             -- ^ The name of this layer
  , _anchor    :: Maybe KeyCode       -- ^ Where to anchor this layer to the source layer
  , _buttons   :: Matrix ButtonSymbol -- ^ A matrix of 'ButtonSymbol's to map to the source
  } deriving (Eq, Show)

-- | Provide some classy lenses for ease of use
makeClassy ''LayerToken


--------------------------------------------------------------------------------

-- | A token representing the entire parse of a configuration file. Note that
-- this does not necessarily correspond to a valid config. The conversion from a
-- 'ConfigToken' to a 'KMonad.Core.Config.Config' is done by
-- 'KMonad.Core.Config.interpret'.
data ConfigToken = ConfigToken
  { _sources :: [SourceToken] -- ^ A list of all the 'SourceToken' encountered
  , _layers  :: [LayerToken]  -- ^ A list of all the 'LayerToken' encountered
  , _aliases :: [AliasDef]    -- ^ A list of all the 'AliasDef' encountered
  , _inputs  :: [InputToken]  -- ^ A list of all the 'InputToken' encountered
  , _outputs :: [OutputToken] -- ^ A list of all the 'OutputToken' encountered
  } deriving (Eq, Show)

-- | Provide some classy lenses for ease of use
makeClassy ''ConfigToken
