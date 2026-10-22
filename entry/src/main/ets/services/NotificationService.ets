import { notificationManager } from '@kit.NotificationKit';
import { common, wantAgent, WantAgent } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppConfig } from './AppConfig';

export class NotificationService {
  private context: common.UIAbilityContext;
  private tapAgent?: WantAgent;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  async init(): Promise<void> {
    try {
      // 新版 Notification Kit 需要在页面加载完成后请求用户授权。
      await notificationManager.requestEnableNotification(this.context);
    } catch (err) {
      const e = err as BusinessError;
      console.warn(`requestEnableNotification: ${e.code} ${e.message}`);
    }

    try {
      const slot: notificationManager.NotificationSlot = {
        type: notificationManager.SlotType.SOCIAL_COMMUNICATION,
        level: notificationManager.SlotLevel.LEVEL_HIGH,
        desc: 'SillyTavern AI 回复完成提醒',
        badgeFlag: true,
        vibrationEnabled: true,
        lightEnabled: true,
      };
      await notificationManager.addSlot(slot);
    } catch (err) {
      const e = err as BusinessError;
      console.warn(`addSlot: ${e.code} ${e.message}`);
    }

    try {
      const info: wantAgent.WantAgentInfo = {
        wants: [{
          bundleName: AppConfig.BUNDLE_NAME,
          abilityName: AppConfig.ABILITY_NAME,
        }],
        actionType: wantAgent.OperationType.START_ABILITY,
        requestCode: 88001,
        actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
      };
      this.tapAgent = await wantAgent.getWantAgent(info);
    } catch (err) {
      const e = err as BusinessError;
      console.warn(`getWantAgent: ${e.code} ${e.message}`);
    }
  }

  async publishReplyFinished(preview: string = ''): Promise<void> {
    const text = preview.trim().length > 0 ? preview.trim().slice(0, 120) : 'AI 已经回复完毕，点击返回酒馆查看。';
    const request: notificationManager.NotificationRequest = {
      id: AppConfig.REPLY_NOTIFICATION_ID,
      notificationSlotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: 'SillyTavern · AI 回复完成',
          text,
          additionalText: '点击打开酒馆',
        },
      },
      wantAgent: this.tapAgent,
      tapDismissed: true,
      badgeNumber: 1,
    };

    try {
      await notificationManager.publish(request);
    } catch (err) {
      const e = err as BusinessError;
      console.error(`publish notification failed: ${e.code} ${e.message}`);
    }
  }
}
