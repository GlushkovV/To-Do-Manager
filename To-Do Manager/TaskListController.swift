//
//  TaskListController.swift
//  To-Do Manager
//
//  Created by Vitaly Glushkov on 29.06.2022.
//

import UIKit

class TaskListController: UITableViewController {
    
    var tasksStorage: TaskStorageProtocol = TasksStorage()
    var tasks: [TaskPriority:[TaskProtocol]] = [:] {
        didSet {
            for (tasksGroupPriority, tasksGroup) in tasks {
                tasks[tasksGroupPriority] = tasksGroup.sorted { task1, task2 in
                    let task1Position = tasksStatusPosition.firstIndex(of: task1.status) ?? 0
                    let task2Position = tasksStatusPosition.firstIndex(of: task2.status) ?? 0
                    return task1Position < task2Position
                }
            }
            var savingArray: [TaskProtocol] = []
            tasks.forEach {key, value in
                savingArray += value
            }
            tasksStorage.saveTasks(savingArray)
        }
    }
    var sectionsTypesPosition: [TaskPriority] = [.important, .normal]
    var tasksStatusPosition: [TaskStatus] = [.planned, .completed]

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = editButtonItem
    }
    
    private func loadTasks() {
        sectionsTypesPosition.forEach { taskType in
            tasks[taskType] = []
        }
        tasksStorage.loadTasks().forEach { task in
            tasks[task.type]?.append(task)
        }
        /*
        // Код сортировки вынесен в сеттер своиства tasks
        for (tasksGroupPriority, tasksGroup) in tasks {
            tasks[tasksGroupPriority] = tasksGroup.sorted { task1, task2 in
                let task1Position = tasksStatusPosition.firstIndex(of: task1.status) ?? 0
                let task2Position = tasksStatusPosition.firstIndex(of: task2.status) ?? 0
                return task1Position < task2Position
            }
        }
        //===========
        // Создает жесткую связь модели и представления не соответствует MVC
        for (tasksGroupPriority, tasksGroup) in tasks {
            tasks[tasksGroupPriority] = tasksGroup.sorted { task1, task2 in
                task1.status.rawValue < task2.status.rawValue
            }
        }
         */
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return tasks.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let taskType = sectionsTypesPosition[section]
        guard let currentTaskType = tasks[taskType] else {
            return 0
        }
        return currentTaskType.count
    }
   
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Ячейка на основе констрейнтов
        //return getConfiguredTaskCell_constraints(for: indexPath)
        // Ячейка на основе стека
        return getConfiguredTaskCell_stack(for: indexPath)
    }
    
    private func getConfiguredTaskCell_constraints(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "taskCellConstraints", for: indexPath)
        let taskType = sectionsTypesPosition[indexPath.section]
        guard let currentTask = tasks[taskType]?[indexPath.row] else {
            return cell
        }
        let symbolLabel = cell.viewWithTag(1) as? UILabel
        let textLabel = cell.viewWithTag(2) as? UILabel
        symbolLabel?.text = getSymbolForTask(with: currentTask.status)
        textLabel?.text = currentTask.title
        if currentTask.status == .planned {
            textLabel?.textColor = .black
            symbolLabel?.textColor = .black
        } else {
            textLabel?.textColor = .lightGray
            symbolLabel?.textColor = .lightGray
        }
        return cell
    }
    
    private func getSymbolForTask(with status: TaskStatus) -> String {
        var resultSymbol: String
        if status == .planned {
            resultSymbol = "\u{25CB}"
        } else if status == .completed {
            resultSymbol = "\u{25C9}"
        } else {
            resultSymbol = ""
        }
        return resultSymbol
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title: String?
        let taskType = sectionsTypesPosition[section]
        if taskType == .important {
            if tasks[taskType]?.count == 0 {
                title = "Важные задачи отсутствуют"
            } else {
                title = "Важные"
            }
        } else if taskType == .normal {
            if tasks[taskType]?.count == 0 {
                title = "Текущие задачи отсутствуют"
            } else {
                title = "Текущие"
            }
        }
        return title
    }
    
    private func getConfiguredTaskCell_stack(for indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "taskCellStack", for: indexPath) as! TaskCell
        let taskType = sectionsTypesPosition[indexPath.section]
        guard let currentTask = tasks[taskType]?[indexPath.row] else {
            return cell
        }
        cell.title.text = currentTask.title
        cell.symbol.text = getSymbolForTask(with: currentTask.status)
        if currentTask.status == .planned {
            cell.title.textColor = .black
            cell.symbol.textColor = .black
        } else {
            cell.title.textColor = .lightGray
            cell.symbol.textColor = .lightGray
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let taskType = sectionsTypesPosition[indexPath.section]
        guard let _ = tasks[taskType]?[indexPath.row] else {
            return
        }
        guard tasks[taskType]![indexPath.row].status == .planned else {
            tableView.deselectRow(at: indexPath, animated: true)
            //Если эту строчку опустить, нажатие по выполненной задаче приведет к ее выделению (перекрасит строку в серый цвет) и не снимет его.
            return
        }
        tasks[taskType]![indexPath.row].status = .completed
        tableView.reloadSections(IndexSet(arrayLiteral: indexPath.section), with: .automatic)
    }
    
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let taskType = sectionsTypesPosition[indexPath.section]
        guard let _ = tasks[taskType]?[indexPath.row] else {
            return nil
        }
        /*
        guard tasks[taskType]![indexPath.row].status == .completed else {
            return nil
        }
        */
        let actionSwipeInstance = UIContextualAction(style: .normal, title: "Не выполнена") { _,_,_ in
            self.tasks[taskType]![indexPath.row].status = .planned
            self.tableView.reloadSections(IndexSet(arrayLiteral: indexPath.section), with: .automatic)
        }
        let actionEditInstance = UIContextualAction(style: .normal, title: "Изменить") { _,_,_ in
            let editScreen = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "TaskEditController") as! TaskEditController
            editScreen.taskText = self.tasks[taskType]![indexPath.row].title
            editScreen.taskType = self.tasks[taskType]![indexPath.row].type
            editScreen.taskStatus = self.tasks[taskType]![indexPath.row].status
            editScreen.doAfterEdit = { [unowned self] title, type, status in
                let editedTask = Task(title: title, type: type, status: status)
                tasks[taskType]![indexPath.row] = editedTask
                tableView.reloadData()
            }
            self.navigationController?.pushViewController(editScreen, animated: true)
        }
        actionEditInstance.backgroundColor = .darkGray
        let actionsConfiguration: UISwipeActionsConfiguration
        if tasks[taskType]![indexPath.row].status == .completed {
            actionsConfiguration = UISwipeActionsConfiguration(actions: [actionSwipeInstance,actionEditInstance])
        } else {
            actionsConfiguration = UISwipeActionsConfiguration(actions: [actionEditInstance])
        }
        return actionsConfiguration
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let taskType = sectionsTypesPosition[indexPath.section]
        tasks[taskType]?.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
    
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let taskTypeForm = sectionsTypesPosition[sourceIndexPath.section]
        let taskTypeTo = sectionsTypesPosition[destinationIndexPath.section]
        guard let movedTask = tasks[taskTypeForm]?[sourceIndexPath.row] else {
            return
        }
        tasks[taskTypeForm]!.remove(at: sourceIndexPath.row)
        tasks[taskTypeTo]!.insert(movedTask, at: destinationIndexPath.row)
        if taskTypeForm != taskTypeTo {
            tasks[taskTypeTo]![destinationIndexPath.row].type = taskTypeTo
        }
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toCreateScreen" {
            let destination = segue.destination as! TaskEditController
            destination.doAfterEdit = { [unowned self] title, type, status in
                let newTask = Task(title: title, type: type, status: status)
                tasks[type]?.append(newTask)
                tableView.reloadData()
            }
        }
    }
    
    func setTasks(_ tasksCollection: [TaskProtocol]) {
        sectionsTypesPosition.forEach { taskType in
            tasks[taskType] = []
        }
        tasksCollection.forEach { task in
            tasks[task.type]?.append(task)
        }
    }

}
