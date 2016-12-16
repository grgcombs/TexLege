//
//  UIColor+SLFUtils.h
//  SLFUtils
//
//  Created by Greg Combs
//

@import UIKit;

BOOL SLFColorGetRGBAComponents(UIColor *color, CGFloat *red, CGFloat *green, CGFloat *blue, CGFloat *alpha);
UIColor *SLFColorWithRGBShift(UIColor *color, int offset);
UIColor *SLFColorWithRGBA(int r, int g, int b, CGFloat a);
UIColor *SLFColorWithRGB(int red,  int green, int blue);
UIColor *SLFColorWithHex(unsigned hex);

typedef struct {
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
} SLFColorRGBComponents;

typedef struct {
    CGFloat hue;
    CGFloat saturation;
    CGFloat brightness;
    CGFloat alpha;
} SLFColorHSBComponents;

BOOL SLFColorIsValidRGBComponents(SLFColorRGBComponents rgb);
BOOL SLFColorIsValidHSBComponents(SLFColorHSBComponents hsb);

@interface UIColor (SLFUtils)

/**
 *  Convenience method for creating a UIColor using simple integer values for red, blue, and green, with
 *  an alpha (transparency) value.
 *
 *  @param r Red integer value (0-255)
 *  @param g Green integer value (0-255)
 *  @param b Blue integer value (0-255)
 *  @param a Alpha value (0.0 - 1.0)
 *
 *  @return A UIColor from the supplied values.
 */
+ (UIColor *)r:(int)r g:(int)g b:(int)b a:(CGFloat)a;


/**
 *  Convenience method for creating a UIColor using simple integer values for red, blue, and green.
 *  Alpha (transparency) is defaulted to 1.0
 *
 *  @param r Red integer value (0-255)
 *  @param g Green integer value (0-255)
 *  @param b Blue integer value (0-255)
 *
 *  @return A UIColor from the supplied values.
 */
+ (UIColor *)r:(int)r g:(int)g b:(int)b;

/**
 *  Create a UIColor using an unsigned hexidecimal value.  Alpha value is defaulted to 1.0
 *
 *  @param hex An unsigned hexidecimal value representing red, blue, green.
 *
 *  @return A UIColor from the supplied value.
 */
+ (UIColor *)colorWithHex:(unsigned)hex;

/**
 *  Create a UIColor using a hexidecimal string, similar to HTML.  Any '#' prefixes are ignored.
 *
 *  @param hexString A hexidecimal string representing a color.  Must be either 3, 6, or 8 characters.
 *                       3 chars: "1CF" - assumes alpha is 1.0
 *                       6 chars: "00AABBCC" - assumes alpha is 1.0
 *                       8 chars: "00AABBCCDD" - sets alpha using last 2 chars
 *
 *  @return A UIColor from the supplied string.
 */
+ (UIColor *)colorWithHexString:(NSString *)hexString;

- (BOOL)canProvideRGBComponents;

- (SLFColorRGBComponents)rgbComponents;

- (SLFColorHSBComponents)hsbComponents;

/**
 *  Offset the red, blue, and green values of the receiver by a fixed value (positive or negative).
 *
 *  @param offset A positive or negative integer to offset by.
 *
 *  @return A UIColor from the supplied offset.
 */
- (UIColor *)colorWithRGBShift:(int)offset;

/**
 *  @author Greg Combs, Dec 10, 2015
 *
 *  Create a new color by blending the receiver color with a secondary color by the amount specified in the ratio.
 *
 *  @param secondColor   A color to blend into the receiver
 *  @param ratio         The proportional amount (0.0 - 1.0) of the second color to blend in
 *  @param blendAlpha    If true, this will blend the alpha channel of the two colors as it does the other RGB channels.
 *                       If false, this creates a flattened color (no alpha).
 *
 *  @return A newly blended color.
 */
- (UIColor *)colorByBlendingWithColor:(UIColor *)secondColor ratio:(double)ratio blendAlpha:(BOOL)blendAlpha;

/**
 *  Given an lower limit color (receiver) and upper limit color, return a mixed color with the supplied proportional ratio.
 *
 *  @param color A UIColor to mix with the receiver.
 *  @param ratio The proportion of the supplied 'color' to mix in.
 *
 *  @return A UIColor from the supplied color and mixing ratio.
 */
- (UIColor *)colorByInterpolatingToColor:(UIColor *)color withRatio:(double)ratio;

/**
 *  Given array of colors and array of color boundaries, and a numeric value, return a color from the
 *  appropriate color "bracket" or (alternatively) return a gradient color interpolation for the numeric value.
 *
 *  For NON-GRADIENT type output (discrete colors):
 *     example boundaries (for 3 colors) are @[ @0.3f, @0.67f ]
 *     boundaries.count must equal (colors.count - 1)
 *  For GRADIENT type output:
 *     boundaries.count must equal colors.count
 *
 *  @param value       A double or float (like 0.5f for 50%) representing the desired position in the color chart.
 *  @param colors      An array of colors to interpolate.
 *  @param boundaries  The proportional positions of the color boundaries.
 *  @param useGradient Use gradient color mixing rather than categorical colors for output.
 *
 *  @return A mixed or categorized color given the supplied values.
 */
+ (UIColor *)interpolatedColorForValue:(id)value colors:(NSArray *)colors boundaries:(NSArray *)boundaries gradient:(BOOL)useGradient;

/**
 *  Return a new color based on the receiver by multiplying the hugh, saturation, and brightness values by parameters supplied.
 *
 *  @param hue        A hue multiplier
 *  @param saturation A saturation multiplier
 *  @param brightness A brightness multiplier
 *
 *  @return A new color given the supplied values
 */
- (UIColor *)multiplyHue:(CGFloat)hue saturation:(CGFloat)saturation brightness:(CGFloat)brightness;
- (UIColor *)multiplyHue:(CGFloat)hue saturation:(CGFloat)saturation lightness:(CGFloat)lightness;

/**
 *  Return a new color based on the receiver by adding the hugh, saturation, and brightness values with the parameters supplied.
 *
 *  @param hue        A hue additive
 *  @param saturation A saturation additive
 *  @param brightness A brightness additive
 *
 *  @return A new color given the supplied values
 */
- (UIColor *)addHue:(CGFloat)hue saturation:(CGFloat)saturation brightness:(CGFloat)brightness;

/**
 *  Return a new color based on the receiver with the following formula: 
 *  multiply hue by 1, saturation by 0.4, brightness by 1.2
 *
 *  @return A new color given the highlight formula.
 */
- (UIColor*)highlight;

/**
 *  Return a new color based on the receiver with the following formula:
 *  multiply hue by 1, saturation by 0.6, brightness by 0.6
 *
 *  @return A new color given the shadow formula.
 */
- (UIColor*)shadow;

/**
 *  Calculate and return the luminance value for the receiver color.
 *  http://en.wikipedia.org/wiki/Luma_(video)
 *   Luminance (Y) = 0.2126 * Red + 0.7152 * Green + 0.0722 * Blue
 *
 *  @return The lumance value for the receiver.
 */
- (CGFloat)luminance;

/**
 *  Calculate and return brightness of the receiver using the HSB (Hue, Saturation, Brightness) color space model.
 *
 *  @return The brightness value.
 */
- (CGFloat)brightness;

/**
 *  Return a new color based on the receiver, and setting the brightness (Hue Saturation *Brightness*) to the 
 *  supplied value along with the alpha (transparency).
 *
 *  @param brightness The desired brightness value given a HSB color space model.
 *  @param alpha      An alpha (transparency) value (0.0 - 1.0)
 *
 *  @return A new color given the supplied values.
 */
- (UIColor *)colorWithBrightness:(CGFloat)brightness alpha:(CGFloat)alpha;

/**
 *  Return a new color based on the receiver, and setting the brightness (Hue Saturation *Brightness*) to the
 *  supplied value.  Alpha is the same as the alpha for the receiver.
 *
 *  @param brightness The desired brightness value given a HSB color space model.
 *
 *  @return A new color given the supplied values.
 */
- (UIColor *)colorWithBrightness:(CGFloat)brightness;

/**
 *  Returns either the white or black color depending on the luminance of the receiver.
 *  If the luma is greater than 50%, it returns black, otherwise it returns white.
 *
 *  @return Either whiteColor or blackColor, whichever contrasts best with the receiver.
 */
- (UIColor *)contrastingColor;

/**
 *  Returns either the white or black color depending on the luma of the receiver color.
 *  If the luma is greater than 80%, it returns black, otherwise it prefers to return white.
 *
 *  @return Either whiteColor or blackColor, whichever contrasts best with the receiver.
 */
- (UIColor *)whiteOrContrastingColor;

/**
 *  Return a new complementary color based on the receiver, with a hue shifted 180 degrees away.
 *
 *  @return A new complementary color.
 */
- (UIColor *)complementaryColor;

/**
 *  Return two new colors that are equidistant on the color wheel from the receiver.
 *  (120 degrees and 240 degress difference in hue from reciever, respectively)
 *
 *  @return An array of two equally spaced colors from the receiver.
 */
- (NSArray *)triadicColors;

/**
 *  Derive new colors from one given color such that they are a set distance on the color wheel from the receiver.
 *
 *  @param stepAngle The step angle distance to position the new colors on the color wheel.
 *  @param pairs     The number of additional pairs of colors to derive.
 *
 *  @return An array containing the collection of new colors.
 */
- (NSArray*)analogousColorsWithStepAngle:(CGFloat)stepAngle pairCount:(NSInteger)pairs;

@end
