extends Node
class_name AdManager

@export var ad_timer: Timer

const banner_unit = "ca-app-pub-3940256099942544/6300978111"
const interstitial_unit = "ca-app-pub-3940256099942544/1033173712"
const rewarded_unit = "ca-app-pub-3940256099942544/5224354917"

var banner: AdView
var interstitial: InterstitialAd
var rewarded: RewardedAd
var content_callback : FullScreenContentCallback
var reward_listener: OnUserEarnedRewardListener

var reward_earned := false

signal ad_done

func show_banner() -> void:
	if banner:
		banner.destroy()
		banner = null
	
	banner = AdView.new(
		banner_unit, AdSize.BANNER, AdPosition.Values.TOP)
	
	banner.load_ad(AdRequest.new())

func show_interstitial() -> void:
	if not ad_timer.is_stopped():
		return
	
	if interstitial:
		interstitial.destroy()
		interstitial = null
	
	var load_callback := InterstitialAdLoadCallback.new()
	
	load_callback.on_ad_failed_to_load = func(_error : LoadAdError) -> void:
		ad_done.emit()
	
	load_callback.on_ad_loaded = func(ad: InterstitialAd) -> void:
		interstitial = ad
		
		interstitial.full_screen_content_callback = content_callback
		interstitial.show()
	
	InterstitialAdLoader.new().load(
		interstitial_unit, AdRequest.new(), load_callback)
	
	await ad_done
	
	ad_timer.start()

func show_rewarded() -> void:
	if rewarded:
		rewarded.destroy()
		rewarded = null
	
	reward_earned = false
	
	var load_callback := RewardedAdLoadCallback.new()
	
	load_callback.on_ad_failed_to_load = func(_error : LoadAdError) -> void:
		ad_done.emit()
	
	load_callback.on_ad_loaded = func(ad: RewardedAd) -> void:
		rewarded = ad
		
		rewarded.full_screen_content_callback = content_callback
		rewarded.show(reward_listener)
	
	RewardedAdLoader.new().load(
		rewarded_unit, AdRequest.new(), load_callback)
	
	await ad_done

func _ready() -> void:
	MobileAds.initialize()
	
	# Set callbacks
	content_callback = FullScreenContentCallback.new()
	content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		ad_done.emit()
	content_callback.on_ad_failed_to_show_full_screen_content = func() -> void:
		ad_done.emit()
	
	reward_listener = OnUserEarnedRewardListener.new()
	reward_listener.on_user_earned_reward = func(_reward: RewardedItem) -> void:
		reward_earned = true
	
	ad_timer.start()
