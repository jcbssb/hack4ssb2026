module SchemaDSL.Altinn
  ( AltinnArtifacts(..)
  , compileToAltinn
  , injectIntoAltinnApp
  , injectIntoAltinnAppPaged
  , compileToAltinnPaged
  , pageName
  , pageLayout
  , enforceEvolutionPageOrder
  , isOwnPage
  , setAppTitle
  , replaceAppTitle
  , updateSettingsPageOrder
  , stripBOM
  , compileSteps
  , compilePredicateToHidden
  ) where

import SchemaDSL.Altinn.Types (AltinnArtifacts(..), pageName, pageLayout)
import SchemaDSL.Altinn.Compile (compileToAltinn, compileToAltinnPaged, compileSteps, compilePredicateToHidden)
import SchemaDSL.Altinn.Inject (injectIntoAltinnApp, injectIntoAltinnAppPaged, isOwnPage, setAppTitle, replaceAppTitle, enforceEvolutionPageOrder, updateSettingsPageOrder, stripBOM)
