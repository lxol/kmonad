{-|
Module      : KMonad.Core.Parser.Parsers.Button
Description : How to parse ButtonTokens
Copyright   : (c) David Janssen, 2019
License     : MIT
Maintainer  : janssen.dhj@gmail.com
Stability   : experimental
Portability : portable

For documentation on how to specify specific buttons please consult
FIXME: insert link

-}
module KMonad.Core.Parser.Parsers.Button
  ( -- * Parse ButtonToken or ButtonSymbol values
    buttonP
  , buttonSymbolP

    -- * Parse a reference to an alias
  , aliasRefP
  )
where

import KMonad.Core.KeyCode
import KMonad.Core.Time
import KMonad.Core.Parser.Parsers.KeyCode
import KMonad.Core.Parser.Utility

import qualified Data.Text as T


--------------------------------------------------------------------------------

-- | Parse a 'ButtonToken'
buttonP :: Parser ButtonToken
buttonP = choice
  [ shifted
  , block
  , modded
  , emit
  , layerToggle
  , multiTap
  , tapHold
  , tapNext
  , tapMacro
  ]

-- | Parse a 'ButtonSymbol' by matching either a 'ButtonToken', an 'AliasRef',
-- or a 'Transparent'.
buttonSymbolP :: Parser ButtonSymbol
buttonSymbolP = choice
  [ BSToken <$> buttonP
  , aliasRefP
  , trans
  ]

-- | Parse an 'AliasRef' as \@name, wrapped in a 'BSAlias' constructor
--
-- We define this here for circular import reasons, but also reexport this
-- parser from "KMonad.Core.Parser.Parsers.Alias"
aliasRefP :: Parser ButtonSymbol
aliasRefP = char '@' *> (BSAlias . AliasRef <$> name)

-- | Parse a 'Transparent' as an underscore, or the symbols "trans" or
-- "transparent"
trans :: Parser ButtonSymbol
trans = Transparent <$ (string "transparent" <|> "trans" <|> "_")


--------------------------------------------------------------------------------
-- Define parsers for each of the different button types

-- | Compound parser for buttons that are 'simple', i.e. that can fill the 'tap'
-- field of any compound 'tap/hold' style button
tapper :: Parser ButtonToken
tapper = emit <|> modded <|> shifted

-- | Parse an emit by reading the name of a keycode
emit :: Parser ButtonToken
emit = BEmit <$> keycodeP

-- | Parse a capital X or the word "block" as a block button
block :: Parser ButtonToken
block = BBlock <$ (string "block" <|> string "X")

-- | Parse a Layer-toggler as "LT-layername"
layerToggle :: Parser ButtonToken
layerToggle = do
  tag <- (string "LT-" >> some alphaNumChar)
  return . BLayerToggle . T.pack $ tag

-- | Parse a TapHold button as "TH delay bTap bHold"
tapHold :: Parser ButtonToken
tapHold = do
  _    <- symbol "TH"
  t    <- read <$> lexeme (some digitChar) :: Parser Int
  tapB <- lexemeSameLine tapper
  hldB <- tapper <|> layerToggle
  return $ BTapHold (fromIntegral t) tapB hldB

-- | Parse a TapNext button as "TN bTap bHold"
tapNext :: Parser ButtonToken
tapNext = do
  _    <- symbol "TN"
  tapB <- lexemeSameLine $ tapper
  hldB <- tapper <|> layerToggle
  return $ BTapNext tapB hldB

-- | Parse a macro button
tapMacro :: Parser ButtonToken
tapMacro = do
  _  <- symbol "||"
  bs <- many (lexemeSameLine tapper)
  _  <- symbol "||"
  pure $ BTapMacro bs

-- | Parse a multi-tap button
multiTap :: Parser ButtonToken
multiTap = do
  _  <- symbol "MT"
  bs <- many (try $ lexemeSameLine one)
  b  <- tapper
  pure . BMultiTap $ bs <> [(0, b)]

  where
    one :: Parser (Microseconds, ButtonToken)
    one = do
      b   <- lexemeSameLine tapper
      num <- read <$> lexemeSameLine (some digitChar) :: Parser Int
      pure (fromIntegral $ 1000 * num, b)

-- | Parse any "S-button" or "C-button" style indicator as a modded button. This
-- is recursive, so "C-S-button" works fine too
modded :: Parser ButtonToken
modded = do
  mod <- choice [ KeyLeftShift  <$ string "S-"
                , KeyLeftCtrl   <$ string "C-"
                , KeyLeftAlt    <$ string "A-"
                , KeyLeftMeta   <$ string "M-"
                , KeyRightShift <$ string "RS-"
                , KeyRightCtrl  <$ string "RC-"
                , KeyRightAlt   <$ string "RA-"
                , KeyRightMeta  <$ string "RM-"
                , KeyCompose    <$ string "CMP-"
                ]
  rest <- modded <|> emit <|> tapMacro
  return $ BModded mod rest

-- | Parse a number of special characters as "the shifted sequence to push
-- them". So "!" gets parsed to a shifted 1, for example. This does not include
-- any capital letters, since those signify special characters.
shifted :: Parser ButtonToken
shifted = try $ (fromNamed m <* notFollowedBy alphaNumChar)
  where
    s = BModded KeyLeftShift . BEmit
    m = [ ( "!",  s Key1)
        , ( "@",  s Key2)
        , ( "#",  s Key3)
        , ( "$",  s Key4)
        , ( "%",  s Key5)
        , ( "^",  s Key6)
        , ( "&",  s Key7)
        , ( "*",  s Key8)
        , ( "(",  s Key9)
        , ( ")",  s Key0)
        , ( "__", s KeyMinus)
        , ( "<",  s KeyComma)
        , ( ">",  s KeyDot)
        , ( "{",  s KeyLeftBrace)
        , ( "}",  s KeyRightBrace)
        , ( "?",  s KeySlash)
        , ( "|",  s KeyBackslash)
        , ( ":",  s KeySemicolon)
        , ( "\"", s KeyApostrophe)
        , ( "~",  s KeyGrave)
        , ( "+",  s KeyEqual) ]
