import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { common, wantAgent, WantAgent } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppConfig } from './AppConfig';

export class BackgroundKeepAlive {
  private context: common.UIAbilityContext;
  private running: boolean = false;
  private continuousNotificationId: number = 0;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  isRunning(): boolean {
    return this.running;
  }

  getNotificationId(): number {
    return this.continuousNotificationId;
  }

  async startForGeneration(): Promise<void> {
    if (this.running) {
      return;
    }

    try {
      const info: wantAgent.WantAgentInfo = {
        wants: [{
          bundleName: AppConfig.BUNDLE_NAME,
          abilityName: AppConfig.ABILITY_NAME,
        }],
        actionType: wantAgent.OperationType.START_ABILITY,
        requestCode: 88002,
        actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
      };
      const agent: WantAgent = await wantAgent.getWantAgent(info);

      // AI 流式生成期间存在持续网络数据传输，因此使用 dataTransfer 长时任务。
      const result = await backgroundTaskManager.startBackgroundRunning(
        this.context,
        ['dataTransfer'],
        agent,
      );
      this.continuousNotificationId = result.notificationId;
      this.running = true;
      console.info(`continuous task started: ${this.continuousNotificationId}`);
    } catch (err) {
      const e = err as BusinessError;
      console.error(`startBackgroundRunning failed: ${e.code} ${e.message}`);
    }
  }

  async stop(): Promise<void> {
    if (!this.running) {
      return;
    }
    try {
      await backgroundTaskManager.stopBackgroundRunning(this.context);
    } catch (err) {
      const e = err as BusinessError;
      console.warn(`stopBackgroundRunning failed: ${e.code} ${e.message}`);
    } finally {
      this.running = false;
      this.continuousNotificationId = 0;
    }
  }
}
